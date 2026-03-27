# Restores conditional uniqueness on license_number when schema drift omitted it.
# Matches CreateProviders — partial index allows multiple NULL/blank if validation ever relaxes.
class AddUniquePartialIndexOnProvidersLicenseNumber < ActiveRecord::Migration[7.2]
  def change
    add_index :providers, :license_number,
              unique: true,
              where: "license_number IS NOT NULL AND license_number != ''",
              if_not_exists: true
  end
end
