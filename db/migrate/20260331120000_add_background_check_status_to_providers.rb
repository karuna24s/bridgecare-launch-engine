class AddBackgroundCheckStatusToProviders < ActiveRecord::Migration[7.2]
  def change
    add_column :providers, :background_check_status, :string
  end
end
