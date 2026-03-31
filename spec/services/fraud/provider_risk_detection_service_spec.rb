# frozen_string_literal: true

require "rails_helper"

RSpec.describe Fraud::ProviderRiskDetectionService do
  let(:provider) { create(:provider, name: "Sunset Daycare") }
  subject(:service) { described_class.new }

  describe "#call" do
    it "automatically flags providers via model callbacks after 4 critical violations" do
      # We expect exactly 1 flag to be created automatically by the
      # after_create_commit hook in the Violation model.
      expect {
        4.times do
          Violation.create!(
            provider: provider,
            category: "safety",
            severity: "critical",
            resolved: false
          )
        end
      }.to change(FraudFlag, :count).by(1)

      flag = FraudFlag.last
      expect(flag.provider).to eq(provider)
      expect(flag.metadata["unresolved_count"]).to eq(4)
    end

    it "does not flag providers with only 3 violations" do
      expect {
        3.times do
          Violation.create!(
            provider: provider,
            category: "safety",
            severity: "critical",
            resolved: false
          )
        end
      }.not_to change(FraudFlag, :count)
    end
  end
end