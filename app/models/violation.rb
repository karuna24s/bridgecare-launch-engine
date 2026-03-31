# frozen_string_literal: true

class Violation < ApplicationRecord
  # Ensure the association back to provider is defined
  belongs_to :provider

  # Use after_create/after_update (not *_commit) so scans run inside the app transaction and
  # fire under RSpec transactional fixtures, where the outer test transaction never commits.
  after_create :trigger_provider_fraud_risk_scan, if: -> { severity == "critical" }
  after_update :trigger_provider_fraud_risk_scan, if: :should_rescan_fraud_risk?

  # Standard Program Assurance validations
  validates :category, :severity, presence: true
  validates :severity, inclusion: { in: %w[critical minor] }
  validates :resolved, inclusion: { in: [ true, false ] }

  # Unresolved violations (resolved is NOT NULL in the database).
  scope :active, -> { where(resolved: false) }
  scope :critical, -> { active.where(severity: "critical") }
  scope :minor, -> { active.where(severity: "minor") }

  private

  def should_rescan_fraud_risk?
    saved_change_to_resolved? || saved_change_to_severity?
  end

  def trigger_provider_fraud_risk_scan
    Fraud::ProviderRiskDetectionService.new.call(provider)
  end
end
