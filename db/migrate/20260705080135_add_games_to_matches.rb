class AddGamesToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :winner_games, :integer
    add_column :matches, :loser_games, :integer
  end
end
