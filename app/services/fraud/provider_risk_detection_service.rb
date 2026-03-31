# frozen_string_literal: true

module Fraud
  class ProviderRiskDetectionService
    def call(provider = nil)
      # Fix: High Severity - Service now accepts an optional single provider
      # for targeted assessment (e.g., from a model callback).
      providers = provider ? [ provider ] : Provider.all

      providers.each do |p|
        unresolved_count = p.violations.where(resolved: false, severity: "critical").count

        next unless unresolved_count > 3

        # Fix: Race can crash fraud flag creation (Medium Severity)
        # create_or_find_by! is atomic at the DB level.
        flag = FraudFlag.create_or_find_by!(
          provider: p,
          flag_type: "high_violation_volume",
          status: "pending"
        )

        # Fix: Flag metadata never refreshes (Low Severity)
        # We explicitly update metadata to reflect the current count.
        flag.update!(
          metadata: flag.metadata.merge(
            "unresolved_count" => unresolved_count,
            "last_detected_at" => Time.current
          )
        )
      end
    end
  end
end
