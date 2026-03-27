# app/services/launch/risk_assessment_service.rb

module Launch
  # RiskAssessmentService calculates a compliance risk score for a provider.
  # Calibrated for BridgeCare's specific schema (Background Checks & Insurance).
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

    def call
      @provider.transaction do
        score = calculate_total_score

        @provider.update!(
          risk_score: score,
          risk_flags: generate_risk_flags(score),
          last_assessed_at: Time.current
        )

        log_assessment_activity(score)
        score
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[RiskAssessmentService] Update failed for Provider ##{@provider.id}: #{e.message}"
      false
    end

    private

    def calculate_total_score
      points = 0

      # 1. Background Check Check
      points += WEIGHTS[:missing_background_check] if @provider.background_check_id.blank?

      # 2. Insurance Check
      points += WEIGHTS[:unverified_insurance] unless @provider.insurance_verified?

      # 3. Violation Logic (Provider defines has_many :violations)
      points += (@provider.violations.critical.count * WEIGHTS[:critical_violation])
      points += (@provider.violations.minor.count * WEIGHTS[:minor_violation])

      [ points, 100 ].min
    end

    def generate_risk_flags(score)
      [].tap do |flags|
        # High Priority: 70 and above
        flags << "HIGH_PRIORITY_AUDIT" if score >= 70

        # Needs Review: Now starts at 1 to catch any violation
        flags << "NEEDS_REVIEW" if score.between?(1, 69)

        flags << "MISSING_BACKGROUND_CHECK" if @provider.background_check_id.blank?
        flags << "INSURANCE_GAP" unless @provider.insurance_verified?

        # Only flag recurring if they have 3 or more
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
