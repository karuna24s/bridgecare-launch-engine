FactoryBot.define do
  factory :activity_log do
    association :loggable, factory: :provider
    action { "eligibility_check" }
    metadata { { score: 100, eligible: true } }
  end
end