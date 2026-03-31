# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fraud::ProviderRiskDetectionService do
  # Using the existing provider factory
  let(:provider) { create(:provider, name: "Sunset Daycare") }
  subject(:service) { described_class.new }

  describe '#call' do
    it 'flags providers with over 3 unresolved critical violations' do
      # Using the discovered 'critical' severity to pass validation
      4.times do
        Violation.create!(
          provider: provider,
          category: 'safety',
          severity: 'critical', # Match the inclusion validator
          resolved: false
        )
      end

      expect { service.call }.to change(FraudFlag, :count).by(1)

      flag = FraudFlag.last
      expect(flag.provider).to eq(provider)
      expect(flag.metadata['unresolved_count']).to eq(4)
    end

    it 'does not flag providers with exactly 3 violations' do
      3.times do
        Violation.create!(
          provider: provider,
          category: 'safety',
          severity: 'minor',
          resolved: false
        )
      end

      expect { service.call }.not_to change(FraudFlag, :count)
    end
  end
end
