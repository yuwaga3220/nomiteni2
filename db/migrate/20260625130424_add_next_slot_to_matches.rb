class AddNextSlotToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :next_slot, :integer
  end
end
