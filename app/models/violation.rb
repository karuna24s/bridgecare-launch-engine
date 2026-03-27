# app/models/violation.rb

class Violation < ApplicationRecord
  # Ensure the association back to provider is defined
  belongs_to :provider

  # Standard Program Assurance validations
  validates :category, :severity, presence: true
  validates :severity, inclusion: { in: %w[critical minor] }
  validates :resolved, inclusion: { in: [ true, false ] }

  # Unresolved: false or NULL (NULL never matches `WHERE resolved = FALSE` in SQL).
  scope :active, -> { where(resolved: false).or(where(resolved: nil)) }
  scope :critical, -> { active.where(severity: "critical") }
  scope :minor, -> { active.where(severity: "minor") }
end
