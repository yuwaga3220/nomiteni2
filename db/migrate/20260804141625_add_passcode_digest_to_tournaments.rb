class AddPasscodeDigestToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :passcode_digest, :string
  end
end
