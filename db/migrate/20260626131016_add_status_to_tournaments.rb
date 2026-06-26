class AddStatusToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :status, :integer, default: 0, null: false
  end
end
