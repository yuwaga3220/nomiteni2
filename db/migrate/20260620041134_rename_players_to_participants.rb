class RenamePlayersToParticipants < ActiveRecord::Migration[8.1]
  def change
    rename_table :players, :participants
  end
end
