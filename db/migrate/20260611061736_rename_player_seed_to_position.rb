class RenamePlayerSeedToPosition < ActiveRecord::Migration[8.1]
  def change
    rename_column :players, :seed, :position
  end
end
