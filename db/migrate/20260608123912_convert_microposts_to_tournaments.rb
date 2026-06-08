class ConvertMicropostsToTournaments < ActiveRecord::Migration[8.1]
  def change
    rename_column :microposts, :content, :title
    add_column    :microposts, :description, :text
    add_column    :microposts, :held_on,     :date
    add_column    :microposts, :venue,       :string
  end
end
