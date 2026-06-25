class Match < ApplicationRecord
  belongs_to :tournament
  belongs_to :participant1, class_name: "Participant", optional: true
  belongs_to :participant2, class_name: "Participant", optional: true
  belongs_to :winner, class_name: "Participant", optional: true
  belongs_to :next_match, class_name: "Match", optional: true
  validates :round, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :next_slot, inclusion: { in: [1, 2] }, allow_nil: true
end
