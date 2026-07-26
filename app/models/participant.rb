class Participant < ApplicationRecord
  belongs_to :tournament
  before_create :set_position
  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: :tournament_id }

  private

  # 新規参加者は末尾に追加する
  def set_position
    self.position ||= (tournament.participants.maximum(:position) || 0) + 1
  end
end
