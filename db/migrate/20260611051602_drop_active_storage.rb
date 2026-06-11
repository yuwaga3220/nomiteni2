class DropActiveStorage < ActiveRecord::Migration[8.1]
  def change
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs
  end
end
