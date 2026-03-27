# app/models/provider.rb
#
# Model: Provider
# Purpose: Core data entity for the Launch Engine.
# Note: Logic is encapsulated in Service Objects to maintain testability.

# app/models/provider.rb

class Provider < ApplicationRecord
  # Established relationship with ActivityLog for the audit trail.
  has_many :activity_logs, as: :loggable, dependent: :destroy

  # New relationship for Program Assurance tracking.
  # If a provider is deleted, their violation history is cleaned up.
  has_many :violations, dependent: :destroy

  # UPDATED: We removed 'license_type' and 'state' because they don't exist in your schema.
  # We now validate the columns we actually have.
  validates :name, :license_number, presence: true

  # Since 'license_expiration_date' is also missing from your column list,
  # we should remove or comment out this method to prevent NoMethodErrors.
  # def license_expired?
  #   false
  # end

  # Returns a user-friendly risk status based on the engine's score.
  def risk_status
    return 'Pending' if last_assessed_at.nil?

    case risk_score
    when 0..30  then 'Low Risk'
    when 31..70 then 'Moderate Risk'
    else 'High Risk'
    end
  end
end
