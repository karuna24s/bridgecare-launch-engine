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

      it 'persists background_check_status from the sync response' do
        service.sync!
        expect(provider.reload.background_check_status).to eq('cleared')
      end

      it 'triggers the RiskAssessmentService' do
        risk_double = instance_double(Launch::RiskAssessmentService)
        allow(Launch::RiskAssessmentService).to receive(:new).with(provider).and_return(risk_double)

        expect(risk_double).to receive(:call).and_return(0)
        service.sync!
      end
    end

    context 'when risk assessment returns false' do
      before do
        allow_any_instance_of(Launch::RiskAssessmentService).to receive(:call).and_return(false)
      end

      it 'rolls back the provider update and returns false' do
        expect(service.sync!).to be false
        expect(provider.reload.background_check_id).to be_nil
        expect(provider.reload.background_check_status).to be_nil
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
