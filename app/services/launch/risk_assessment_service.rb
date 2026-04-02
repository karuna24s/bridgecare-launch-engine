# app/services/launch/risk_assessment_service.rb

module Launch
  # Raised when {#call} cannot complete (e.g. RecordInvalid).
  class RiskAssessmentError < StandardError; end

  class RiskAssessmentService
    # Weights for the BridgeCare Program Assurance logic.
    WEIGHTS = {
      missing_background_check: 40,
      unverified_insurance: 20,
      critical_violation: 30,
      minor_violation: 10
    }.freeze

    def initialize(provider, changed_by: "System")
      @provider = provider
      @changed_by = changed_by
    end

    # Performs the risk assessment and persists results with an audit trail.
    # @raise [Launch::RiskAssessmentError] if the update or audit fails.
    # @return [Integer] the calculated risk score.
    def call
      @provider.transaction do
        old_score = @provider.risk_score || 0
        new_score = calculate_total_score
        breakdown = generate_breakdown

        # 1. Update the Provider state
        @provider.update!(
          risk_score: new_score,
          risk_flags: generate_risk_flags(new_score),
          last_assessed_at: Time.current
        )

        # 2. Create the Immutable Audit Record (Senior III Requirement)
        # This ensures every score change is legally and technically traceable.
        @provider.risk_assessment_audits.create!(
          old_score: old_score,
          new_score: new_score,
          score_breakdown: breakdown,
          reason: "Automated Program Assurance Engine Update",
          changed_by: @changed_by
        )

        # 3. Maintain legacy activity log for general event tracking
        log_assessment_activity(new_score)

        new_score
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error "[RiskAssessmentService] Update failed for Provider ##{@provider.id}: #{e.message}"
      raise RiskAssessmentError, "Validation failed during risk assessment: #{e.message}"
    end

    private

    def calculate_total_score
      points = 0

      # 1. Background Check Check
      points += WEIGHTS[:missing_background_check] if @provider.background_check_id.blank?

      # 2. Insurance Check
      points += WEIGHTS[:unverified_insurance] unless @provider.insurance_verified?

      # 3. Violation Logic
      points += (@provider.violations.critical.count * WEIGHTS[:critical_violation])
      points += (@provider.violations.minor.count * WEIGHTS[:minor_violation])

      [ points, 100 ].min # Cap the score at 100
    end

    # Captures the exact inputs used for the calculation.
    # Essential for future compliance audits if weights change.
    def generate_breakdown
      {
        weights_version: "v1",
        data_snapshot: {
          unresolved_violations: @provider.violations.unresolved.count,
          has_background_check: @provider.background_check_id.present?,
          insurance_verified: @provider.insurance_verified?,
          active_fraud_flags: @provider.fraud_flags.active.count
        }
      }
    end

    def generate_risk_flags(score)
      [].tap do |flags|
        flags << "HIGH_PRIORITY_AUDIT" if score >= 70
        flags << "NEEDS_REVIEW" if score.positive?
        flags << "MISSING_BACKGROUND_CHECK" if @provider.background_check_id.blank?
        flags << "INSURANCE_GAP" unless @provider.insurance_verified?
        flags << "RECURRING_VIOLATIONS" if @provider.violations.active.count >= 3
      end
    end

    def log_assessment_activity(score)
      @provider.activity_logs.create!(
        action: "risk_assessment_performed",
        metadata: {
          score: score,
          engine: "bridgecare-assurance-v1",
          timestamp: Time.current
        }
      )
    end
  end
end
