# spec/services/launch/eligibility_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::EligibilityService do
  describe "Factory Integration" do
    context "when using a standard compliant provider" do
      let(:provider) { build(:provider) } # Standard TX provider from factory
      subject(:service) { Launch::EligibilityService.new(provider) }

      it "is eligible by default" do
        expect(service.call[:eligible]).to be true
      end
    end

    context "when the provider is in California" do
      subject(:service) { Launch::EligibilityService.new(provider) }

      it "fails if not CA-compliant" do
        provider = build(:provider, :in_california)
        expect(Launch::EligibilityService.new(provider).call[:eligible]).to be false
      end

      it "passes if fully CA-compliant" do
        provider = build(:provider, :ca_compliant)
        expect(Launch::EligibilityService.new(provider).call[:eligible]).to be true
      end
    end
  end
end