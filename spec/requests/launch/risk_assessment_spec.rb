# spec/requests/launch/risk_assessment_spec.rb
require 'rails_helper'

RSpec.describe "Program Assurance Engine", type: :request do
  let(:provider) do
    Provider.create!(
      name: "Ayodhya Early Learning",
      license_number: "RN-2026-TEST",
      background_check_id: "BC-108",
      insurance_verified: true
    )
  end

  describe "Risk Calculation Logic" do
    it "calculates a score of 30 for a single critical violation" do
      # Create the violation that triggers the score
      provider.violations.create!(
        category: "Safety",
        severity: "critical",
        occurred_on: Date.current
      )

      # Execute the service
      service = Launch::RiskAssessmentService.new(provider)
      score = service.call

      expect(score).to eq(30)
      expect(provider.reload.risk_score).to eq(30)
      expect(provider.risk_flags).to include("NEEDS_REVIEW")
    end

    it "caps the score at 100 even with excessive violations" do
      # Add 15 minor violations (150 points potentially)
      15.times do
        provider.violations.create!(category: "Admin", severity: "minor")
      end

      Launch::RiskAssessmentService.new(provider).call

      expect(provider.reload.risk_score).to eq(100)
      expect(provider.risk_flags).to include("NEEDS_REVIEW", "HIGH_PRIORITY_AUDIT")
    end
  end

  describe "Audit Trail" do
    it "creates an activity log entry after assessment" do
      expect {
        Launch::RiskAssessmentService.new(provider).call
      }.to change(ActivityLog, :count).by(1)

      last_log = ActivityLog.last
      expect(last_log.action).to eq('risk_assessment_performed')
      expect(last_log.metadata['engine']).to eq('bridgecare-assurance-v1')
    end
  end
end
