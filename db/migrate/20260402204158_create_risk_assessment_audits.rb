# db/migrate/20260402170000_create_risk_assessment_audits.rb
class CreateRiskAssessmentAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :risk_assessment_audits do |t|
      t.references :provider, null: false, foreign_key: true
      t.integer :old_score
      t.integer :new_score
      t.jsonb :score_breakdown, default: {}
      t.string :reason
      t.string :changed_by

      t.timestamps
    end

    add_index :risk_assessment_audits, :score_breakdown, using: :gin
  end
end
