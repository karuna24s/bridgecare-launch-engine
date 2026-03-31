# db/migrate/20260331150000_create_fraud_flags.rb
class CreateFraudFlags < ActiveRecord::Migration[7.2]
  def change
    create_table :fraud_flags do |t|
      t.references :provider, null: false, foreign_key: true # Point to the actual table
      t.string :flag_type, null: false # e.g., 'high_violation_count'
      t.string :status, default: 'pending', null: false
      t.jsonb :metadata, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
