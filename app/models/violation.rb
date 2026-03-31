# frozen_string_literal: true

class Violation < ApplicationRecord
  # Ensure the association back to provider is defined
  belongs_to :provider

  # Fix: Risk detection service is never executed (High Severity)
  # Automatically triggers assessment when a critical violation is logged.
  after_create_commit :trigger_risk_assessment, if: -> { severity == "critical" }

  # Standard Program Assurance validations
  validates :category, :severity, presence: true
  validates :severity, inclusion: { in: %w[critical minor] }
  validates :resolved, inclusion: { in: [ true, false ] }

  # Unresolved violations (resolved is NOT NULL in the database).
  scope :active, -> { where(resolved: false) }
  scope :critical, -> { active.where(severity: "critical") }
  scope :minor, -> { active.where(severity: "minor") }

  private

  def trigger_risk_assessment
    # This ensures our new Fraud engine is actually utilized in production
    Fraud::ProviderRiskDetectionService.new.call(provider)
  end
end
