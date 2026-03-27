# app/models/violation.rb

class Violation < ApplicationRecord
  # Ensure the association back to provider is defined
  belongs_to :provider

  # Standard Program Assurance validations
  validates :category, :severity, presence: true
  validates :severity, inclusion: { in: %w[critical minor] }

  # Scopes for the Risk Engine
  scope :active, -> { where(resolved: false) }
  scope :critical, -> { active.where(severity: 'critical') }
  scope :minor, -> { active.where(severity: 'minor') }
end

