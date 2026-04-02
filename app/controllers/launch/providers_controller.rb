# app/controllers/launch/providers_controller.rb
# frozen_string_literal: true

module Launch
  class ProvidersController < ApplicationController
    # POST /launch/providers/:id/evaluate
    def evaluate
      provider = Provider.find(params[:id])

      # Senior III: We attribute the change to a "Manual-Advocate" for the audit trail
      service = Launch::RiskAssessmentService.new(provider, changed_by: "Manual-Advocate")
      service.call

      redirect_back fallback_location: launch_dashboard_path,
                    notice: "Risk assessment recalculated for #{provider.name}."
    rescue Launch::RiskAssessmentError => e
      redirect_back fallback_location: launch_dashboard_path,
                    alert: "Assessment failed: #{e.message}"
    end
  end
end
