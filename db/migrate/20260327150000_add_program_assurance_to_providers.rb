# db/migrate/20260327150000_add_program_assurance_to_providers.rb

class AddProgramAssuranceToProviders < ActiveRecord::Migration[7.2]
  def change
    # Create the violations table to track compliance history.
    # A provider's risk score is directly tied to these records.
    create_table :violations do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :category, null: false # e.g., 'Safety', 'Health', 'Financial'
      t.string :severity, null: false # 'critical' or 'minor'
      t.text :description
      t.boolean :resolved, null: false, default: false
      t.date :occurred_on
      t.timestamps
    end

    # Upgrade the providers table with fields for the Risk Engine's output.
    # risk_flags uses jsonb for flexible, indexed tagging of specific risks.
    change_table :providers do |t|
      t.integer :risk_score, default: 0
      t.jsonb :risk_flags, default: []
      t.datetime :last_assessed_at
    end

    # Indexing for performance in the Program Assurance dashboard.
    add_index :providers, :risk_score
    add_index :providers, :risk_flags, using: :gin
  end
end
