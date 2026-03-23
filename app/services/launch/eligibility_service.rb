# app/services/launch/eligibility_service.rb
#
# Service: Launch::EligibilityService
# Role: Dynamic Regulatory Engine.
# ADR 2: Leverages JSONB for state-specific compliance.

module Launch
  class EligibilityService
    # Universal requirements for every provider in the system
    CORE_REQUIREMENTS = [ :license_number, :background_check_id, :insurance_verified ].freeze

    def initialize(provider)
      @provider = provider
    end

    def call
      @errors = []
      eligible = valid?
      score = calculate_score
      missing = @errors.freeze
      {
        eligible: eligible,
        score: score,
        missing: missing,
        state: provider_state,
        analyzed_at: Time.current.iso8601
      }
    end

    def call_with_logging(note: nil)
      result = call

      @provider.activity_logs.create!(
        action: "eligibility_check",
        note: note,
        metadata: {
          score: result[:score],
          eligible: result[:eligible],
          issues: result[:missing],
          state: result[:state]
        }
      )

      result
    end

    private

    def valid?
      all_rules.each do |rule|
        @errors << "Missing #{rule.to_s.humanize}" unless rule_met?(rule)
      end
      @errors.empty?
    end

    # The 'Scale' Logic: California requires a Health & Safety certification.
    def state_specific_requirements
      case provider_state
      when "CA"
        [ :health_safety_certified ]
      when "NY"
        [ :site_inspection_passed ]
      else
        []
      end
    end

    def provider_state
      @provider.compliance_data&.[]("state_code")&.upcase
    end

    def calculate_score
      rules = all_rules
      return 100 if rules.empty?
      met_count = rules.count { |rule| rule_met?(rule) }
      ((met_count.to_f / rules.size) * 100).round
    end

    def all_rules
      CORE_REQUIREMENTS + state_specific_requirements
    end

    def rule_met?(rule)
      value = rule_value(rule)
      value.present? && value != false
    end

    def rule_value(rule)
      @provider.respond_to?(rule) ? @provider.send(rule) : @provider.compliance_data&.[](rule.to_s)
    end
  end
end
