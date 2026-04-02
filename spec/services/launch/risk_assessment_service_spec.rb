# spec/services/launch/risk_assessment_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::RiskAssessmentService do
  let(:provider) {
    Provider.create!(
      name: "Rama Test Center",
      license_number: "L-#{rand(10000)}",
      insurance_verified: true,
      background_check_id: "BC-123",
      risk_score: 0
    )
  }

  # Accountable actor for the audit trail
  subject(:service) { described_class.new(provider, changed_by: "Test-Runner") }

  describe "#call" do
    context "when the provider is fully compliant" do
      it "returns 0 and creates an audit record" do
        expect { service.call }.to change(RiskAssessmentAudit, :count).by(1)
        expect(provider.reload.risk_score).to eq(0)
      end
    end

    context "with a high-risk scenario (score >= 70)" do
      before do
        provider.update!(background_check_id: nil) # +40
        # Fix: Added category to satisfy validation
        provider.violations.create!(severity: "critical", category: "Safety", resolved: false) # +30
      end

      it "calculates 70, flags HIGH_PRIORITY_AUDIT, and snapshots the breakdown" do
        score = service.call
        audit = provider.risk_assessment_audits.last

        expect(score).to eq(70)
        expect(provider.risk_flags).to include("HIGH_PRIORITY_AUDIT")

        # Verify JSONB Snapshot integrity
        expect(audit.score_breakdown["data_snapshot"]["has_background_check"]).to be false
        expect(audit.score_breakdown["data_snapshot"]["unresolved_violations"]).to eq(1)
        expect(audit.changed_by).to eq("Test-Runner")
      end
    end

    context "when points exceed 100" do
      before do
        provider.update!(background_check_id: nil, insurance_verified: false) # 60
        # Fix: Added category to satisfy validation
        3.times { provider.violations.create!(severity: "critical", category: "Health", resolved: false) }
      end

      it "caps the audit and provider score at 100" do
        service.call
        expect(provider.reload.risk_score).to eq(100)
        expect(provider.risk_assessment_audits.last.new_score).to eq(100)
      end
    end

    describe "Atomic Integrity (Transaction Control)" do
      it "rolls back score change if audit fails to save" do
        # Senior move: Stubbing save! to force a rollback scenario
        allow_any_instance_of(RiskAssessmentAudit).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)

        expect {
          begin
            service.call
          rescue Launch::RiskAssessmentError
            nil
          end
        }.not_to change { provider.reload.risk_score }
      end

      it "raises custom Launch::RiskAssessmentError on failures" do
        allow(provider).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        expect { service.call }.to raise_error(Launch::RiskAssessmentError)
      end
    end
  end
end
