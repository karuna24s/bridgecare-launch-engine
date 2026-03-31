# app/services/fraud/provider_risk_detection_service.rb
module Fraud
  class ProviderRiskDetectionService
    def call
      Provider.find_each do |provider|
        # Focus on 'critical' unresolved violations based on the model's inclusion list
        unresolved_count = provider.violations.where(resolved: false, severity: "critical").count

        if unresolved_count > 3
          FraudFlag.find_or_create_by!(
            provider: provider,
            flag_type: "high_violation_volume",
            status: "pending"
          ) do |flag|
            flag.metadata = { unresolved_count: unresolved_count }
          end
        end
      end
    end
  end
end
