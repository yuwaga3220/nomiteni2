class Participant < ApplicationRecord
  belongs_to :tournament
  before_create :set_position
  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: :tournament_id }

  # この選手が現在出場している（最も後のラウンドの）試合を返す
  def current_match
    tournament.matches.where("participant1_id = :id OR participant2_id = :id", id: id)
              .order(round: :desc).first
  end

  # 棄権にし、出場中の試合を相手の不戦勝にする。
  # 棄権にできない場合はerrorsに理由を追加してfalseを返す
  def withdraw
    return true if withdrawn?
    match = current_match
    if match&.finished?
      errors.add(:base, "結果が確定している試合の選手は棄権にできません")
      return false
    end
    opponent = match && (match.participant1_id == id ? match.participant2 : match.participant1)
    if opponent&.withdrawn?
      errors.add(:base, "対戦相手も棄権しているため、棄権にできません")
      return false
    end
    transaction do
      update!(withdrawn: true)
      if match
        match.reload.predictions.destroy_all
        match.apply_walkover!
      end
    end
    true
  end

  # 棄権を取り消し、不戦勝の結果と進出を元に戻す。
  # 次の試合が開始済みで取り消せない場合はerrorsに理由を追加してfalseを返す
  def cancel_withdrawal
    return true unless withdrawn?
    match = current_match
    if match&.result_locked?
      errors.add(:base, "次の試合が開始しているため、棄権を取り消せません")
      return false
    end
    transaction do
      update!(withdrawn: false)
      if match
        match.cancel_walkover!
        # 相手がその後棄権していた場合は、こちらの不戦勝にする
        match.apply_walkover!
      end
    end
    true
  end

  private

  # 新規参加者は末尾に追加する
  def set_position
    self.position ||= (tournament.participants.maximum(:position) || 0) + 1
  end
end
