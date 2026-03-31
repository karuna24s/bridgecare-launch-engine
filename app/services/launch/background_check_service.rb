# app/services/launch/background_check_service.rb
# Service to manage the ingestion and synchronization of 3rd-party background check data.
# This supports the 'Program Assurance' initiative by automating risk factor updates.

module Launch
  class BackgroundCheckService
    def initialize(provider)
      @provider = provider
    end

    def sync!
      # External I/O outside the transaction so we do not hold a DB connection during HTTP / vendor latency.
      response = fetch_external_data

      # Provider update + risk scoring must commit together; risk service returns false on failure without raising.
      ActiveRecord::Base.transaction do
        @provider.update!(
          background_check_id: response[:id],
          background_check_status: response[:status],
          last_assessed_at: Time.current
        )

        risk_result = Launch::RiskAssessmentService.new(@provider).call
        raise RiskAssessmentError, "Risk assessment did not complete" if risk_result == false
      end

      true
    rescue StandardError => e
      Rails.logger.error "[BackgroundCheckService] Sync failed for Provider #{@provider.id}: #{e.message}"
      false
    end

    private

    def fetch_external_data
      # Simulating a call to a State Background Check API
      # In a production environment, this would use Faraday or Net::HTTP
      {
        id: "BGC-#{SecureRandom.hex(6).upcase}",
        status: "cleared"
      }
    end
  end
end
