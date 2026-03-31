# frozen_string_literal: true

module Fraud
  # Evaluates unresolved critical violation volume per provider and maintains a pending
  # `high_violation_volume` FraudFlag, or clears it when back under threshold.
  # Prefer `call(provider)` from callbacks; `call` with no args scans all providers.
  class ProviderRiskDetectionService
    FLAG_TYPE = "high_violation_volume"

    def call(provider = nil)
      if provider
        evaluate_provider!(provider)
      else
        Provider.find_each { |p| evaluate_provider!(p) }
      end
    end

    private

    def evaluate_provider!(provider)
      unresolved_count = provider.violations.where(resolved: false, severity: "critical").count
      pending_flag = provider.fraud_flags.pending.find_by(flag_type: FLAG_TYPE)

      if unresolved_count > 3
        upsert_pending_flag!(provider, unresolved_count)
      elsif pending_flag
        pending_flag.update!(
          status: "cleared",
          metadata: (pending_flag.metadata || {}).merge(
            "cleared_at" => Time.current.iso8601,
            "cleared_reason" => "below_threshold",
            "unresolved_count_at_clear" => unresolved_count
          )
        )
      end
    end

    def upsert_pending_flag!(provider, unresolved_count)
      provider.with_lock do
        flag = provider.fraud_flags.pending.find_by(flag_type: FLAG_TYPE)
        if flag
          flag.update!(metadata: metadata_merge(flag.metadata, unresolved_count))
        else
          begin
            provider.fraud_flags.create!(
              flag_type: FLAG_TYPE,
              status: "pending",
              metadata: metadata_merge({}, unresolved_count)
            )
          rescue ActiveRecord::RecordNotUnique
            flag = provider.fraud_flags.pending.find_by(flag_type: FLAG_TYPE)
            flag&.update!(metadata: metadata_merge(flag.metadata, unresolved_count))
          end
        end
      end
    rescue ActiveRecord::RecordNotUnique
      flag = provider.fraud_flags.pending.find_by(flag_type: FLAG_TYPE)
      flag&.update!(metadata: metadata_merge(flag&.metadata, unresolved_count))
    end

    def metadata_merge(existing, unresolved_count)
      (existing || {}).merge(
        "unresolved_count" => unresolved_count,
        "last_detected_at" => Time.current.iso8601
      )
    end
  end
end
