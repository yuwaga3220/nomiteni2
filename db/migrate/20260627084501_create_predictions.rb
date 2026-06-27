class CreatePredictions < ActiveRecord::Migration[8.1]
  def change
    create_table :predictions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :predicted_participant, null: false,
                   foreign_key: { to_table: :participants }
      t.timestamps
    end
    add_index :predictions, [ :user_id, :match_id ], unique: true
  end
end
