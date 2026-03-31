# app/services/launch/background_check_service.rb
# Service to manage the ingestion and synchronization of 3rd-party background check data.
# This supports the 'Program Assurance' initiative by automating risk factor updates.

module Launch
  class BackgroundCheckService
    def initialize(provider)
      @provider = provider
    end

    def sync!
      # We wrap this in a transaction to ensure that the provider update
      # and the subsequent risk re-assessment happen atomically.
      ActiveRecord::Base.transaction do
        response = fetch_external_data

        @provider.update!(
          background_check_id: response[:id],
          # Note: Ensure background_check_status is added to your schema if not present
          last_assessed_at: Time.current
        )

        # Immediately re-calculate risk now that we have background check data
        Launch::RiskAssessmentService.new(@provider).call
      end
    rescue StandardError => e
      # Basic error logging for the 'In Review' phase
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
