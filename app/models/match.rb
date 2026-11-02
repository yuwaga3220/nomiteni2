class Match < ApplicationRecord
  belongs_to :tournament
  belongs_to :participant1, class_name: "Participant", optional: true
  belongs_to :participant2, class_name: "Participant", optional: true
  belongs_to :winner, class_name: "Participant", optional: true
  belongs_to :next_match, class_name: "Match", optional: true
  has_many :predictions, dependent: :destroy
  enum :status, { pending: 0, in_progress: 1, finished: 2 }
  validates :round, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :next_slot, inclusion: { in: [ 1, 2 ] }, allow_nil: true
  validates :winner_games, :loser_games, :participant1_games, :participant2_games, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :winner_games_must_exceed_loser_games, if: -> { winner_games.present? || loser_games.present? }

  # ブラケットに表示する、指定した枠（1 or 2）の選手のゲーム数。
  # 勝者が決まっていれば確定した結果、未確定ならタップで加算した途中スコアを返す
  def games_for(slot)
    return slot == 1 ? participant1_games : participant2_games if winner.nil?

    winner == (slot == 1 ? participant1 : participant2) ? winner_games : loser_games
  end

  # 途中スコアが両者入力済みで、勝敗がつく（同点でない）状態か
  def live_result_ready?
    !finished? && participant1_games.present? && participant2_games.present? &&
      participant1_games != participant2_games
  end

  # 次の試合が既に始まっている（予備でない）場合、この試合の結果は変更できない
  def result_locked?
    next_match.present? && !next_match.pending?
  end

  # 棄権した選手を含む試合（不戦勝の試合）かどうか
  def walkover?
    !!(participant1&.withdrawn? || participant2&.withdrawn?)
  end

  # 勝者を次の試合の対応する枠へ進める
  def advance_winner!
    return unless next_match && next_slot
    next_match.update!(next_slot == 1 ? { participant1: winner } : { participant2: winner })
  end

  # 棄権者を含む試合なら、相手を勝者として不戦勝で確定し、勝者を次の試合へ進める。
  # 不戦勝の試合は予想の対象外なので予想は削除する。進出先も不戦勝なら連鎖して確定する。
  # 両者棄権の場合は片方を形式上の勝者として進め、次の試合を相手の不戦勝にする
  def apply_walkover!
    return unless walkover? && winner_id.nil?
    walkover_winner = participant1&.withdrawn? ? participant2 : participant1
    return if walkover_winner.nil?
    predictions.destroy_all
    update!(winner: walkover_winner, winner_games: nil, loser_games: nil, status: :finished)
    advance_winner!
    next_match&.apply_walkover!
  end

  # 不戦勝の結果と、そこから次の試合へ進出した選手を取り消す
  def cancel_walkover!
    return unless finished?
    next_match.update!(next_slot == 1 ? { participant1: nil } : { participant2: nil }) if next_match && next_slot
    update!(winner: nil, status: :pending)
  end

  private

  def winner_games_must_exceed_loser_games
    errors.add(:base, "勝者のゲーム数は敗者のゲーム数より多くなければなりません") if winner_games.to_i <= loser_games.to_i
  end
end
