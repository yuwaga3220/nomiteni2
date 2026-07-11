class AddPointsToPredictions < ActiveRecord::Migration[8.1]
  def change
    add_column :predictions, :points, :integer
  end
end
