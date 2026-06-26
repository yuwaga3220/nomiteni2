class Tournament < ApplicationRecord
  belongs_to :user
  has_many :participants, dependent: :destroy
  has_many :matches, dependent: :destroy
  default_scope -> { order(created_at: :desc) }
  enum :status, { before: 0, during: 1, after: 2 }
  validates :user_id, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :venue, length: { maximum: 100 }, allow_blank: true
end
