# Aligns DB with AddProgramAssuranceToProviders and fixes schema.rb drift where resolved lost null: false.
class EnsureViolationsResolvedNotNull < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE violations SET resolved = FALSE WHERE resolved IS NULL"
    change_column_null :violations, :resolved, false
  end

  def down
    change_column_null :violations, :resolved, true
  end
end
