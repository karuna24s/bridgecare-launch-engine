# spec/services/launch/background_check_service_spec.rb
require 'rails_helper'

RSpec.describe Launch::BackgroundCheckService do
  let(:provider) { create(:provider, background_check_id: nil, background_check_status: nil) }
  let(:service) { described_class.new(provider) }
  let(:risk_double) { instance_double(Launch::RiskAssessmentService) }

  describe '#sync!' do
    context 'when the external sync is successful' do
      before do
        # Avoid `.with(provider)` — same in-memory instance is not guaranteed across reload/callbacks.
        allow(Launch::RiskAssessmentService).to receive(:new).and_return(risk_double)
        allow(risk_double).to receive(:call).and_return(10)
      end

      it 'updates the provider background_check_id' do
        expect { service.sync! }.to change { provider.reload.background_check_id }.from(nil)
      end

      it 'persists background_check_status from the sync response' do
        service.sync!
        expect(provider.reload.background_check_status).to eq('cleared')
      end

      it 'triggers the RiskAssessmentService' do
        expect(risk_double).to receive(:call).and_return(10)
        service.sync!
      end
    end

    context 'when risk assessment fails' do
      it 'rolls back the provider background check updates' do
        allow(Launch::RiskAssessmentService).to receive(:new).and_return(risk_double)
        # Simulate the Hard Failure we implemented
        allow(risk_double).to receive(:call).and_raise(Launch::RiskAssessmentError.new("Persistence failed"))

        service.sync!

        # Verify rollback: The BGC ID should still be nil despite the earlier update! call
        expect(provider.reload.background_check_id).to be_nil
        expect(provider.reload.background_check_status).to be_nil
      end
    end
  end
end
