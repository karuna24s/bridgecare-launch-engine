# spec/services/launch/risk_assessment_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::RiskAssessmentService do
  # We use 'let' to create a clean provider for each test case
  let(:provider) {
    Provider.create!(
      name: "Rama Test Center",
      license_number: "L-108",
      background_check_id: "BC-123",
      insurance_verified: true
    )
  }

  subject(:service) { described_class.new(provider) }

  describe "#call" do
    context "when the provider is fully compliant" do
      it "returns a risk score of 0" do
        expect(service.call).to eq(0)
        expect(provider.risk_score).to eq(0)
      end
    end

    context "when a background check is missing" do
      before { provider.update(background_check_id: nil) }

      it "assigns 40 points to the risk score" do
        expect(service.call).to eq(40)
        expect(provider.risk_flags).to include("MISSING_BACKGROUND_CHECK")
      end
    end

    context "with a mix of violations" do
      before do
        # Trigger 40 points
        provider.update(background_check_id: nil)
        # Trigger 30 points
        provider.violations.create!(category: "Safety", severity: "critical")
        # Trigger 10 points
        provider.violations.create!(category: "Admin", severity: "minor")
      end

      it "calculates the correct weighted total" do
        # 40 + 30 + 10 = 80
        expect(service.call).to eq(80)
        expect(provider.risk_flags).to include("HIGH_PRIORITY_AUDIT", "NEEDS_REVIEW")
      end
    end

    context "with a single critical violation" do
      before do
        provider.violations.create!(
          category: "Safety",
          severity: "critical",
          occurred_on: Date.current
        )
      end

      it "assigns 30 points and NEEDS_REVIEW" do
        expect(service.call).to eq(30)
        expect(provider.reload.risk_score).to eq(30)
        expect(provider.risk_flags).to include("NEEDS_REVIEW")
      end
    end

    context "when violations would exceed the score cap" do
      before do
        15.times do
          provider.violations.create!(category: "Admin", severity: "minor")
        end
      end

      it "caps the score at 100 and sets high-severity flags" do
        service.call
        expect(provider.reload.risk_score).to eq(100)
        expect(provider.risk_flags).to include("NEEDS_REVIEW", "HIGH_PRIORITY_AUDIT")
      end
    end

    context "data integrity" do
      it "updates the last_assessed_at timestamp" do
        expect { service.call }.to change { provider.last_assessed_at }
      end

      it "creates an activity log with assessment metadata" do
        expect { service.call }.to change(ActivityLog, :count).by(1)
        last_log = ActivityLog.last
        expect(last_log.action).to eq("risk_assessment_performed")
        expect(last_log.metadata["engine"]).to eq("bridgecare-assurance-v1")
      end
    end
  end
end
