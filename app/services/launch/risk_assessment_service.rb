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

    # Single source of truth for weighted points (used by {#calculate_total_score} and audit JSON).
    def score_calculation_parts
      crit_count = @provider.violations.critical.count
      minor_count = @provider.violations.minor.count

      pts_bg = @provider.background_check_id.blank? ? WEIGHTS[:missing_background_check] : 0
      pts_ins = @provider.insurance_verified? ? 0 : WEIGHTS[:unverified_insurance]
      pts_crit = crit_count * WEIGHTS[:critical_violation]
      pts_minor = minor_count * WEIGHTS[:minor_violation]

      raw = pts_bg + pts_ins + pts_crit + pts_minor
      {
        critical_violation_count: crit_count,
        minor_violation_count: minor_count,
        points_background_check: pts_bg,
        points_insurance: pts_ins,
        points_critical_violations: pts_crit,
        points_minor_violations: pts_minor,
        raw_points_before_cap: raw,
        final_score: [ raw, 100 ].min
      }
    end

    def calculate_total_score
      score_calculation_parts[:final_score]
    end

    # Captures inputs and point lines that reproduce {#calculate_total_score} (compliance / audits).
    def generate_breakdown
      parts = score_calculation_parts
      {
        weights_version: "v1",
        weights: WEIGHTS.transform_keys(&:to_s),
        data_snapshot: {
          has_background_check: @provider.background_check_id.present?,
          insurance_verified: @provider.insurance_verified?,
          critical_violation_count: parts[:critical_violation_count],
          minor_violation_count: parts[:minor_violation_count],
          points_background_check: parts[:points_background_check],
          points_insurance: parts[:points_insurance],
          points_critical_violations: parts[:points_critical_violations],
          points_minor_violations: parts[:points_minor_violations],
          raw_points_before_cap: parts[:raw_points_before_cap],
          score_after_cap: parts[:final_score]
        },
        supplemental_context: {
          unresolved_violations_total: @provider.violations.unresolved.count,
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
