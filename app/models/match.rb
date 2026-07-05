class Match < ApplicationRecord
  belongs_to :tournament
  belongs_to :participant1, class_name: "Participant", optional: true
  belongs_to :participant2, class_name: "Participant", optional: true
  belongs_to :winner, class_name: "Participant", optional: true
  belongs_to :next_match, class_name: "Match", optional: true
  has_many :predictions, dependent: :destroy
  validates :round, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :next_slot, inclusion: { in: [1, 2] }, allow_nil: true
  validates :winner_games, :loser_games, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :winner_games_must_exceed_loser_games, if: -> { winner_games.present? || loser_games.present? }

  private

  def winner_games_must_exceed_loser_games
    errors.add(:base, "勝者のゲーム数は敗者のゲーム数より多くなければなりません") if winner_games.to_i <= loser_games.to_i
  end
end
