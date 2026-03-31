# app/controllers/providers_controller.rb
# Handles coordination for Provider-specific compliance and risk data.
# This controller acts as the entry point for the Program Assurance engine.

class ProvidersController < ApplicationController
  # POST /providers/:id/sync_background_check
  # Triggers an external sync of background check data and re-calculates risk.
  def sync_background_check
    @provider = Provider.find(params[:id])

    # We delegate the complexity to the Service Object.
    # This keeps our controller "skinny" and easily testable.
    service = Launch::BackgroundCheckService.new(@provider)

    if service.sync!
      # Success: The RiskAssessmentService was also triggered inside sync!
      redirect_to provider_path(@provider),
                  notice: "Background check for #{@provider.name} successfully synchronized. Risk score updated."
    else
      # Failure: Likely a network or database issue logged in the service.
      redirect_to provider_path(@provider),
                  alert: "Failed to synchronize background check. Please check system logs."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to providers_path, alert: "Provider not found."
  end
end
