class Prediction < ApplicationRecord
  belongs_to :user
  belongs_to :match
  belongs_to :predicted_participant, class_name: "Participant"
  validates :user_id, uniqueness: { scope: :match_id }
end
