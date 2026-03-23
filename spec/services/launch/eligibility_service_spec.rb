# spec/services/launch/eligibility_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::EligibilityService do
  # Using 'build' for logic tests to keep them fast;
  # 'create' is used only when testing database side-effects.
  let(:provider) { build(:provider) }
  subject(:service) { Launch::EligibilityService.new(provider) }

  describe "#call (Logic Engine)" do
    context "with Factory defaults" do
      it "is eligible by default" do
        expect(service.call[:eligible]).to be true
      end
    end

    context "when the provider is in California" do
      it "fails if not CA-compliant" do
        ca_provider = build(:provider, :in_california)
        result = Launch::EligibilityService.new(ca_provider).call
        expect(result[:eligible]).to be false
        expect(result[:missing]).to include("Missing Health safety certified")
      end

      it "passes if fully CA-compliant" do
        ca_provider = build(:provider, :ca_compliant)
        result = Launch::EligibilityService.new(ca_provider).call
        expect(result[:eligible]).to be true
        expect(result[:score]).to eq(100)
      end
    end
  end

  describe "#call_with_logging (Audit Trail)" do
    # We must 'create' the provider here so it has an ID for the polymorphic association
    let(:persisted_provider) { create(:provider) }
    subject(:logging_service) { Launch::EligibilityService.new(persisted_provider) }

    it "persists an ActivityLog record in the database" do
      expect {
        logging_service.call_with_logging(note: "Manual check")
      }.to change(ActivityLog, :count).by(1)
    end

    it "captures the correct metadata in the log" do
      logging_service.call_with_logging
      last_log = persisted_provider.activity_logs.last

      expect(last_log.action).to eq('eligibility_check')
      expect(last_log.metadata['score']).to eq(100)
      expect(last_log.metadata['state']).to eq('TX')
    end
  end
end