require 'rails_helper'

RSpec.describe ActivityLog, type: :model do
  let(:provider) { create(:provider, :in_california) }

  it "creates a log entry when an eligibility check is performed" do
    expect {
      Launch::EligibilityService.new(provider).call_with_logging(note: "Monthly Audit")
    }.to change(ActivityLog, :count).by(1)

    last_log = ActivityLog.last
    expect(last_log.action).to eq('eligibility_check')
    expect(last_log.metadata['state']).to eq('CA')
    expect(last_log.note).to eq("Monthly Audit")
  end
end
