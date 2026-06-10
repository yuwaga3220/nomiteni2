class DropRelationships < ActiveRecord::Migration[8.1]
  def change
    drop_table :relationships
  end
end
