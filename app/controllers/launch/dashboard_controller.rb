# app/controllers/launch/dashboard_controller.rb
module Launch
  class DashboardController < ApplicationController
    def index
      # Fetch high-risk providers for the primary queue
      high_risk_providers = Provider.where("risk_score > ?", 70)
                                    .order(risk_score: :desc)
                                    .limit(10)

      # Fetch recent audits for the activity timeline
      recent_audits = RiskAssessmentAudit.includes(:provider)
                                         .order(created_at: :desc)
                                         .limit(10)

      # Inertia.render maps to app/javascript/Pages/Launch/Dashboard.vue
      render inertia: "Launch/Dashboard", props: {
        providers: high_risk_providers.as_json(methods: [ :risk_flags ]),
        audits: recent_audits.as_json(include: { provider: { only: :name } })
      }
    end
  end
end
