class ActivityLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true

  validates :action, presence: true

  # Scope to quickly find recent eligibility checks
  scope :eligibility_checks, -> { where(action: 'eligibility_check') }
end
