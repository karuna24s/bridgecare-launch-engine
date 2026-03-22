# spec/factories/providers.rb
# Blueprint for Provider data using Faker for realism.

FactoryBot.define do
  factory :provider do
    name { Faker::Company.name + " Daycare" }
    license_number { "LIC-#{Faker::Number.number(digits: 5)}" }
    background_check_id { "BC-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    insurance_verified { true }
    compliance_data { { 'state_code' => 'TX' } }

    # Trait for a provider that hasn't started the process
    trait :incomplete do
      license_number { nil }
      background_check_id { nil }
      insurance_verified { false }
    end

    # Trait for California-specific requirements
    trait :in_california do
      compliance_data { { 'state_code' => 'CA' } }
    end

    # Trait for a fully compliant California provider
    trait :ca_compliant do
      in_california
      compliance_data { { 'state_code' => 'CA', 'health_safety_certified' => true } }
    end
  end
end
