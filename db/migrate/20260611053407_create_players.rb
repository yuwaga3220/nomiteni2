class CreatePlayers < ActiveRecord::Migration[8.1]
  def up
    drop_table :players, if_exists: true
    create_table :players do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :seed
      t.timestamps
    end
    add_index :players, [:tournament_id, :name], unique: true
  end

  def down
    drop_table :players
  end
end
