class AddLiveGamesToMatches < ActiveRecord::Migration[8.1]
  def change
    # ブラケットのタップで加算する途中スコア（確定すると winner_games / loser_games に移る）
    add_column :matches, :participant1_games, :integer
    add_column :matches, :participant2_games, :integer
  end
end
