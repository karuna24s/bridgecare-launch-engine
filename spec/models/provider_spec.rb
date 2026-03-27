# spec/models/provider_spec.rb
require 'rails_helper'

RSpec.describe Provider, type: :model do
  let(:provider) { Provider.new(name: "Test", license_number: "123") }

  describe "Validations" do
    it "is valid with a name and license number" do
      expect(provider).to be_valid
    end

    it "is invalid without a name" do
      provider.name = nil
      expect(provider).not_to be_valid
      expect(provider.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a license_number" do
      provider.license_number = nil
      expect(provider).not_to be_valid
      expect(provider.errors[:license_number]).to include("can't be blank")
    end

    it "is invalid when license_number is not unique" do
      Provider.create!(name: "Existing", license_number: "LIC-DUP-1")
      dup = Provider.new(name: "Other", license_number: "LIC-DUP-1")
      expect(dup).not_to be_valid
      expect(dup.errors[:license_number]).to include("has already been taken")
    end
  end

  describe "Associations" do
    it "can have many violations" do
      assoc = described_class.reflect_on_association(:violations)
      expect(assoc.macro).to eq :has_many
    end

    it "can have many activity_logs" do
      assoc = described_class.reflect_on_association(:activity_logs)
      expect(assoc.macro).to eq :has_many
    end
  end

  describe "#risk_status" do
    before { provider.last_assessed_at = Time.current }

    it "returns 'Low Risk' for a score of 30" do
      provider.risk_score = 30
      expect(provider.risk_status).to eq('Low Risk')
    end

    it "returns 'Moderate Risk' up to 69 (aligned with risk_flags NEEDS_REVIEW max)" do
      provider.risk_score = 69
      expect(provider.risk_status).to eq('Moderate Risk')
    end

    it "returns 'High Risk' from 70 onward (aligned with HIGH_PRIORITY_AUDIT threshold)" do
      provider.risk_score = 70
      expect(provider.risk_status).to eq('High Risk')
    end
  end
end
