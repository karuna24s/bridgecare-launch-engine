class CreateActivityLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :activity_logs do |t|
      t.references :loggable, polymorphic: true, null: false
      t.string :action, null: false # e.g., 'eligibility_check'
      t.jsonb :metadata, default: {} # Stores the score, issues, and state_code
      t.string :note

      t.timestamps
    end
  end
end
