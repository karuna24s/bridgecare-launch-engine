# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

demo = Provider.find_or_initialize_by(license_number: 'DEMO-ASSESS-001')
demo.assign_attributes(
  name: 'Audit Demo Center',
  background_check_id: nil,
  insurance_verified: false
)
demo.save!

# Push score above dashboard threshold (70): 40 + 20 + 30 = 90
demo.violations.find_or_create_by!(category: 'Safety', severity: 'critical') do |v|
  v.resolved = false
end

Launch::RiskAssessmentService.new(demo, changed_by: 'db:seed').call
