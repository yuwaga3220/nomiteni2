class AddPositionToParticipants < ActiveRecord::Migration[8.1]
  class MigrationParticipant < ActiveRecord::Base
    self.table_name = "participants"
  end

  def up
    add_column :participants, :position, :integer

    MigrationParticipant.distinct.pluck(:tournament_id).each do |tournament_id|
      MigrationParticipant.where(tournament_id: tournament_id).order(:created_at, :id)
                           .each_with_index do |participant, index|
        participant.update_column(:position, index + 1)
      end
    end
  end

  def down
    remove_column :participants, :position
  end
end
