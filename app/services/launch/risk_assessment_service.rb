# app/services/launch/risk_assessment_service.rb

module Launch
  # Raised when {#call} cannot complete (e.g. RecordInvalid).
  # This ensures that calling services can roll back their parent transactions on failure.
  class RiskAssessmentError < StandardError; end

  class RiskAssessmentService
    # Weights for the BridgeCare Program Assurance logic.
    WEIGHTS = {
      missing_background_check: 40,
      unverified_insurance: 20,
      critical_violation: 30,
      minor_violation: 10
    }.freeze

    def initialize(provider)
      @provider = provider
    end

    # Performs the risk assessment and persists results.
    # @raise [Launch::RiskAssessmentError] if the update fails.
    # @return [Integer] the calculated risk score.
    def call
      @provider.transaction do
        score = calculate_total_score

        # We use update! to trigger an exception if validations fail,
        # ensuring the transaction rolls back.
        @provider.update!(
          risk_score: score,
          risk_flags: generate_risk_flags(score),
          last_assessed_at: Time.current
        )

        log_assessment_activity(score)
        score
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
      # Senior Detail: Using .count to delegate the calculation to the DB.
      points += (@provider.violations.critical.count * WEIGHTS[:critical_violation])
      points += (@provider.violations.minor.count * WEIGHTS[:minor_violation])

      [ points, 100 ].min # Cap the score at 100
    end

    def generate_risk_flags(score)
      [].tap do |flags|
        flags << "HIGH_PRIORITY_AUDIT" if score >= 70
        flags << "NEEDS_REVIEW" if score.positive?
        flags << "MISSING_BACKGROUND_CHECK" if @provider.background_check_id.blank?
        flags << "INSURANCE_GAP" unless @provider.insurance_verified?

        # Logic for recurring patterns
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
