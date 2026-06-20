class Tournament < ApplicationRecord
  belongs_to :user
  has_many :participants, dependent: :destroy
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :venue, length: { maximum: 100 }, allow_blank: true
end
