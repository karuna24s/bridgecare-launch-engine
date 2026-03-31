# frozen_string_literal: true

require "rails_helper"

RSpec.describe FraudFlag, type: :model do
  let(:provider) { Provider.create!(name: "Test Provider", license_number: "LIC-#{SecureRandom.hex(4)}") }

  describe "associations" do
    it "belongs to a provider" do
      flag = FraudFlag.new(provider: provider)
      expect(flag.provider).to eq(provider)
    end
  end

  describe "validations" do
    it "is invalid without a flag_type" do
      flag = FraudFlag.new(flag_type: nil)
      expect(flag).not_to be_valid
      expect(flag.errors[:flag_type]).to include("can't be blank")
    end

    it "is invalid without a status" do
      flag = FraudFlag.new(status: nil)
      expect(flag).not_to be_valid
      expect(flag.errors[:status]).to include("can't be blank")
    end
  end

  describe "database constraints" do
    it "enforces uniqueness on provider_id and flag_type for pending flags" do
      # Create the first record
      FraudFlag.create!(
        provider: provider,
        flag_type: "high_violation_volume",
        status: "pending"
      )

      # Explicitly build the duplicate
      duplicate_flag = FraudFlag.new(
        provider: provider,
        flag_type: "high_violation_volume",
        status: "pending"
      )

      # Senior Move: Use 'save' without validations to hit the DB index directly
      expect {
        duplicate_flag.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
