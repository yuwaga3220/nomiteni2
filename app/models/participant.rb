class Participant < ApplicationRecord
  belongs_to :tournament
  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: :tournament_id }
end
