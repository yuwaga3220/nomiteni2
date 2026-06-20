class RemovePositionFromParticipants < ActiveRecord::Migration[8.1]
  def change
    remove_column :participants, :position, :integer
  end
end
