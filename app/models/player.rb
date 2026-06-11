class Player < ApplicationRecord
  belongs_to :tournament
  validates :name, presence: true, length: { maximum: 50 },
                   uniqueness: { scope: :tournament_id }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
