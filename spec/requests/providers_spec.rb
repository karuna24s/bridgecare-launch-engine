# spec/requests/providers_spec.rb
require 'rails_helper'

RSpec.describe "Providers", type: :request do
  let(:provider) { create(:provider, name: "Sunrise Daycare") }

  describe "POST /providers/:id/sync_background_check" do
    context "when the provider exists" do
      it "calls the BackgroundCheckService and redirects with success" do
        # We mock the service success
        allow_any_instance_of(Launch::BackgroundCheckService).to receive(:sync!).and_return(true)

        post sync_background_check_provider_path(provider)

        expect(response).to redirect_to(provider_path(provider))
        expect(flash[:notice]).to match(/successfully synchronized/)
      end

      it "redirects with an alert if the service fails" do
        allow_any_instance_of(Launch::BackgroundCheckService).to receive(:sync!).and_return(false)

        post sync_background_check_provider_path(provider)

        expect(response).to redirect_to(provider_path(provider))
        expect(flash[:alert]).to match(/Failed to synchronize/)
      end
    end

    context "when the provider does not exist" do
      it "redirects to the index with a 404 alert" do
        post "/providers/9999/sync_background_check"

        expect(response).to redirect_to(providers_path)
        expect(flash[:alert]).to eq('Provider not found.')
      end
    end
  end
end
