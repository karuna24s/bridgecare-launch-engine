# spec/models/violation_spec.rb
require 'rails_helper'

RSpec.describe Violation, type: :model do
  let(:provider) { Provider.create!(name: "Test", license_number: "123") }
  let(:violation) { Violation.new(provider: provider, category: "Safety", severity: "critical") }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(violation).to be_valid
    end

    it "is invalid with a bad severity" do
      violation.severity = "extreme"
      expect(violation).not_to be_valid
      expect(violation.errors[:severity]).to include("is not included in the list")
    end

    it "is invalid without a category" do
      violation.category = nil
      expect(violation).not_to be_valid
    end
  end

  describe "Scopes" do
    it "filters unresolved critical violations" do
      critical = provider.violations.create!(category: "Safety", severity: "critical", resolved: false)
      resolved = provider.violations.create!(category: "Safety", severity: "critical", resolved: true)

      expect(Violation.critical).to include(critical)
      expect(Violation.critical).not_to include(resolved)
    end
  end
end
