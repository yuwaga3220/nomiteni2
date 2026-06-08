class RenameMicropostsToTournaments < ActiveRecord::Migration[8.1]
  def change
    rename_table :microposts, :tournaments
    rename_index :tournaments, 'index_microposts_on_user_id', 'index_tournaments_on_user_id'
    rename_index :tournaments, 'index_microposts_on_user_id_and_created_at', 'index_tournaments_on_user_id_and_created_at'
    reversible do |dir|
      dir.up do
        execute "UPDATE active_storage_attachments SET record_type = 'Tournament' WHERE record_type = 'Micropost'"
      end
      dir.down do
        execute "UPDATE active_storage_attachments SET record_type = 'Micropost' WHERE record_type = 'Tournament'"
      end
    end
  end
end
