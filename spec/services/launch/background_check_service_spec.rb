# spec/services/launch/background_check_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::BackgroundCheckService do
  let(:provider) { create(:provider, background_check_id: nil) }
  let(:service) { described_class.new(provider) }

  describe '#sync!' do
    context 'when the external sync is successful' do
      it 'updates the provider background_check_id' do
        expect { service.sync! }.to change { provider.reload.background_check_id }.from(nil)
      end

      it 'triggers the RiskAssessmentService' do
        # We mock the RiskAssessmentService to ensure this service is delegating correctly
        risk_double = instance_double(Launch::RiskAssessmentService)
        allow(Launch::RiskAssessmentService).to receive(:new).with(provider).and_return(risk_double)

        expect(risk_double).to receive(:call)
        service.sync!
      end
    end

    context 'when a database error occurs' do
      it 'logs the error and returns false' do
        allow(provider).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        expect(Rails.logger).to receive(:error).with(/Sync failed/)

        expect(service.sync!).to be false
      end
    end
  end
end
