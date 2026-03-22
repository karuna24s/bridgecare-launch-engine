class CreateProviders < ActiveRecord::Migration[7.2]
  def change
    create_table :providers do |t|
      t.string :name
      t.string :license_number
      t.string :background_check_id
      t.boolean :insurance_verified
      t.jsonb :compliance_data

      t.timestamps
    end
  end
end
