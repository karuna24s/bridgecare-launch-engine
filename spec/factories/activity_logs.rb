# spec/factories/activity_logs.rb
# Blueprint for polymorphic Activity Logs.

FactoryBot.define do
  factory :activity_log do
    # Polymorphic association: defaults to creating a new provider
    association :loggable, factory: :provider

    action { "eligibility_check" }
    note { "Automated system check" }

    # Default metadata matching the EligibilityService output
    metadata do
      {
        score: 100,
        eligible: true,
        issues: [],
        state: "TX"
      }
    end

    # Trait for a failed check
    trait :failed do
      note { "Compliance failure detected" }
      metadata do
        {
          score: 33,
          eligible: false,
          issues: ["Missing License number", "Missing Insurance verified"],
          state: "CA"
        }
      end
    end
  end
end