# frozen_string_literal: true

require "rails_helper"

RSpec.describe Fraud::ProviderRiskDetectionService do
  let(:provider) { create(:provider, name: "Sunset Daycare") }
  subject(:service) { described_class.new }

  describe "#call" do
    it "automatically flags providers via model callbacks after 4 critical violations" do
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
      expect(flag.status).to eq("pending")
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

    it "clears a pending flag when unresolved critical count drops to 3 or below" do
      violations = []
      4.times do
        violations << Violation.create!(
          provider: provider,
          category: "safety",
          severity: "critical",
          resolved: false
        )
      end

      expect(FraudFlag.pending.where(provider: provider).count).to eq(1)

      violations.first.update!(resolved: true)

      expect(FraudFlag.pending.where(provider: provider).count).to eq(0)
      cleared = FraudFlag.where(provider: provider, flag_type: "high_violation_volume").last
      expect(cleared.status).to eq("cleared")
      expect(cleared.metadata["cleared_reason"]).to eq("below_threshold")
      expect(cleared.metadata["unresolved_count_at_clear"]).to eq(3)
    end

    it "refreshes metadata on repeat scans above threshold" do
      4.times do
        Violation.create!(
          provider: provider,
          category: "safety",
          severity: "critical",
          resolved: false
        )
      end

      flag_id = FraudFlag.pending.find_by!(provider: provider).id

      Violation.create!(
        provider: provider,
        category: "safety",
        severity: "critical",
        resolved: false
      )

      service.call(provider)

      expect(FraudFlag.find(flag_id).metadata["unresolved_count"]).to eq(5)
    end

    it "clears a pending flag when a critical violation is destroyed" do
      violations = []
      4.times do
        violations << Violation.create!(
          provider: provider,
          category: "safety",
          severity: "critical",
          resolved: false
        )
      end

      expect(FraudFlag.pending.where(provider: provider).count).to eq(1)

      violations.first.destroy!

      expect(FraudFlag.pending.where(provider: provider).count).to eq(0)
      cleared = FraudFlag.where(provider: provider, flag_type: "high_violation_volume").last
      expect(cleared.status).to eq("cleared")
      expect(cleared.metadata["unresolved_count_at_clear"]).to eq(3)
    end

    it "rescans both providers when a critical violation is reassigned" do
      other = create(:provider)

      4.times do
        Violation.create!(
          provider: provider,
          category: "safety",
          severity: "critical",
          resolved: false
        )
      end
      3.times do
        Violation.create!(
          provider: other,
          category: "safety",
          severity: "critical",
          resolved: false
        )
      end

      expect(FraudFlag.pending.where(provider: provider).count).to eq(1)
      expect(FraudFlag.pending.where(provider: other).count).to eq(0)

      movable = provider.violations.critical.first
      movable.update!(provider: other)

      expect(FraudFlag.pending.where(provider: provider).count).to eq(0)
      expect(FraudFlag.pending.where(provider: other).count).to eq(1)
    end
  end
end
