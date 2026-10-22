class AddWithdrawnToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :withdrawn, :boolean, default: false, null: false
  end
end
