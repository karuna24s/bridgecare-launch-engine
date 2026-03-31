class AddLastBgcSyncAtToProviders < ActiveRecord::Migration[7.2]
  def change
    add_column :providers, :last_bgc_sync_at, :datetime
  end
end
