# spec/services/launch/risk_assessment_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::RiskAssessmentService do
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
        provider.update(background_check_id: nil) # 40
        provider.violations.create!(category: "Safety", severity: "critical") # 30
        provider.violations.create!(category: "Admin", severity: "minor") # 10
      end

      it "calculates the correct weighted total" do
        expect(service.call).to eq(80)
        expect(provider.risk_flags).to include("HIGH_PRIORITY_AUDIT", "NEEDS_REVIEW")
      end
    end

    context "with a single critical violation" do
      before do
        provider.violations.create!(
          category: "Safety",
          severity: "critical",
          resolved: false
        )
      end

      it "adds critical_violation weight to the score" do
        expect(service.call).to eq(30)
        expect(provider.risk_flags).to include("NEEDS_REVIEW")
        expect(provider.risk_flags).not_to include("HIGH_PRIORITY_AUDIT")
      end
    end

    context "when raw points would exceed 100" do
      before do
        provider.update!(background_check_id: nil, insurance_verified: false)
        3.times do
          provider.violations.create!(
            category: "Safety",
            severity: "critical",
            resolved: false
          )
        end
      end

      it "caps the persisted risk score at 100" do
        # 40 + 20 + (3 * 30) = 150 before [points, 100].min
        expect(service.call).to eq(100)
        expect(provider.reload.risk_score).to eq(100)
        expect(provider.risk_flags).to include("HIGH_PRIORITY_AUDIT")
      end
    end

    context "data integrity" do
      it "updates the last_assessed_at timestamp" do
        expect { service.call }.to change { provider.last_assessed_at }
      end

      it "creates an activity log with assessment metadata" do
        expect { service.call }.to change(ActivityLog, :count).by(1)
        expect(ActivityLog.last.action).to eq("risk_assessment_performed")
      end
    end
  end
end
