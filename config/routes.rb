# config/routes.rb
Rails.application.routes.draw do
  # Existing resource routes
  resources :providers, only: [ :show, :index ] do
    member do
      post :sync_background_check
    end
  end

  # Program Assurance Engine
  namespace :launch do
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Manual Trigger Route
    resources :providers, only: [] do
      member do
        # POST /launch/providers/:id/evaluate
        post :evaluate
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
