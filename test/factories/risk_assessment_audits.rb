FactoryBot.define do
  factory :risk_assessment_audit do
    association :provider
    old_score { 1 }
    new_score { 1 }
    score_breakdown { {} }
    reason { "MyString" }
    changed_by { "MyString" }
  end
end
