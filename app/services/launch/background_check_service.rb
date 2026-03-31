# app/services/launch/background_check_service.rb

module Launch
  class BackgroundCheckService
    def initialize(provider)
      @provider = provider
    end

    # Orchestrates the background check sync and subsequent risk assessment.
    # @return [Boolean] true if the entire operation succeeded and committed.
    def sync!
      # 1. I/O Isolation: Fetch data outside the DB transaction to avoid connection holding.
      response = fetch_external_data
      return false unless response

      # 2. Transactional Integrity: Ensure both updates succeed or both roll back.
      ActiveRecord::Base.transaction do
        # Do not set last_assessed_at here — RiskAssessmentService#call writes it when the risk run completes.
        @provider.update!(
          background_check_id: response[:id],
          background_check_status: response[:status],
          last_bgc_sync_at: Time.current
        )

        # 3. Hard Failure Pattern: This will raise Launch::RiskAssessmentError on failure,
        # triggering a rollback of the provider update above.
        Launch::RiskAssessmentService.new(@provider).call
      end

      true
    rescue Launch::RiskAssessmentError => e
      Rails.logger.error "[BackgroundCheckService] Risk Assessment failed: #{e.message}"
      false
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[BackgroundCheckService] Provider update failed: #{e.message}"
      false
    rescue StandardError => e
      Rails.logger.error "[BackgroundCheckService] Unexpected error: #{e.message}"
      false
    end

    private

    def fetch_external_data
      # Simulating an external API call.
      {
        id: "BGC-#{SecureRandom.hex(6).upcase}",
        status: "cleared"
      }
    rescue StandardError => e
      Rails.logger.error "[BackgroundCheckService] External API fetch failed: #{e.message}"
      nil
    end
  end
end
