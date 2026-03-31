# frozen_string_literal: true

class Violation < ApplicationRecord
  # Ensure the association back to provider is defined
  belongs_to :provider

  # after_*_commit so each scan sees fully committed rows (concurrent inserts can cross the
  # threshold only after commit). Callback specs that rely on these use real commits — see
  # Fraud::ProviderRiskDetectionService spec (use_transactional_tests: false).
  after_create_commit :trigger_provider_fraud_risk_scan, if: -> { severity == "critical" }
  after_update_commit :trigger_provider_fraud_risk_scan_after_update
  after_destroy_commit :trigger_provider_fraud_risk_scan_on_destroy, if: :was_critical_unresolved_for_fraud_scan?

  # Standard Program Assurance validations
  validates :category, :severity, presence: true
  validates :severity, inclusion: { in: %w[critical minor] }
  validates :resolved, inclusion: { in: [ true, false ] }

  # Unresolved violations (resolved is NOT NULL in the database).
  scope :active, -> { where(resolved: false) }
  scope :critical, -> { active.where(severity: "critical") }
  scope :minor, -> { active.where(severity: "minor") }

  private

  def was_critical_unresolved_for_fraud_scan?
    severity == "critical" && !resolved
  end

  def trigger_provider_fraud_risk_scan
    p = Provider.find_by(id: provider_id)
    Fraud::ProviderRiskDetectionService.new.call(p) if p
  end

  # previous_changes is the supported API during after_commit (saved_change_* is cleared).
  def trigger_provider_fraud_risk_scan_after_update
    ch = previous_changes
    return unless ch.key?("resolved") || ch.key?("severity") || ch.key?("provider_id")

    ids = []
    if ch.key?("provider_id")
      old_id, = ch["provider_id"]
      ids << old_id if old_id
    end
    ids << provider.id if provider.persisted?
    Fraud::ProviderRiskDetectionService.scan_providers_by_sorted_ids!(ids)
  end

  def trigger_provider_fraud_risk_scan_on_destroy
    p = Provider.find_by(id: provider_id)
    Fraud::ProviderRiskDetectionService.new.call(p) if p
  end
end
