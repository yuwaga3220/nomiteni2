class AddCourtAndStatusToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :court, :string
    add_column :matches, :status, :integer, default: 0, null: false
  end
end
