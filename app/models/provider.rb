# frozen_string_literal: true

# Model: Provider
# Purpose: Core data entity for the Launch Engine.
# Note: Logic is encapsulated in Service Objects to maintain testability.

class Provider < ApplicationRecord
  # Established relationship with ActivityLog for the audit trail.
  has_many :activity_logs, as: :loggable, dependent: :destroy

  # New relationship for Program Assurance tracking.
  # If a provider is deleted, their violation history is cleaned up.
  has_many :violations, dependent: :destroy

  # BUGFIX: Provider deletion blocked by new foreign key (Medium Severity)
  # Ensures related fraud flags are removed to avoid foreign key violations.
  has_many :fraud_flags, dependent: :destroy

  # Validating the columns that actually exist in the schema.
  validates :name, presence: true
  validates :license_number, presence: true, uniqueness: true

  # Returns a user-friendly risk status based on the engine's score.
  def risk_status
    return "Pending" if last_assessed_at.nil?

    case risk_score
    when 0..30  then "Low Risk"
    when 31..69 then "Moderate Risk"
    else "High Risk"
    end
  end
end
