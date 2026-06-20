class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :participant1, foreign_key: { to_table: :participants }
      t.references :participant2, foreign_key: { to_table: :participants }
      t.references :winner, foreign_key: { to_table: :participants }
      t.references :next_match, foreign_key: { to_table: :matches }
      t.integer :round, null: false

      t.timestamps
    end
  end
end
