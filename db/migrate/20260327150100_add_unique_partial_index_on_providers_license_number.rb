# Restores conditional uniqueness on license_number when schema drift omitted it.
# Matches CreateProviders — partial index allows multiple NULL/blank if validation ever relaxes.
class AddUniquePartialIndexOnProvidersLicenseNumber < ActiveRecord::Migration[7.2]
  def up
    deduplicate_provider_license_numbers

    add_index :providers, :license_number,
              unique: true,
              where: "license_number IS NOT NULL AND license_number != ''",
              if_not_exists: true
  end

  def down
    remove_index :providers, name: "index_providers_on_license_number", if_exists: true
  end

  private

  def deduplicate_provider_license_numbers
    say_with_time "Deduplicating provider license_number values before unique index" do
      duplicate_licenses = connection.select_values <<~SQL.squish
        SELECT license_number
        FROM providers
        WHERE license_number IS NOT NULL AND license_number != ''
        GROUP BY license_number
        HAVING COUNT(*) > 1
      SQL

      duplicate_licenses.each do |ln|
        ids = connection.select_values <<~SQL.squish
          SELECT id FROM providers
          WHERE license_number = #{connection.quote(ln)}
          ORDER BY id ASC
        SQL

        ids[1..].each do |id|
          new_val = "#{ln}-dedup-#{id}"
          new_val = new_val[-255..] if new_val.length > 255
          execute <<~SQL.squish
            UPDATE providers
            SET license_number = #{connection.quote(new_val)}
            WHERE id = #{id.to_i}
          SQL
        end
      end
    end
  end
end
