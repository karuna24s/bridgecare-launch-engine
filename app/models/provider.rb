# app/models/provider.rb
#
# Model: Provider
# Purpose: Core data entity for the Launch Engine.
# Note: Logic is encapsulated in Service Objects to maintain testability.

class Provider < ApplicationRecord
  # ADR 2: PostgreSQL JSONB for flexible compliance data (e.g., state-specific certs)
  # This allows the Engine to check for 'health_safety_signed' without a migration.
  store_accessor :compliance_data, :state_code, :health_safety_signed

  validates :name, presence: true
  validates :license_number, uniqueness: true, allow_blank: true

  # Senior Move: A convenience method to trigger the engine
  def eligibility
    Launch::EligibilityService.new(self).call
  end
end
