# frozen_string_literal: true

class FraudFlag < ApplicationRecord
  belongs_to :provider

  validates :flag_type, presence: true
  validates :status, presence: true

  # Helper to identify if a flag is still actionable
  scope :pending, -> { where(status: "pending") }
  scope :active, -> { pending }
end
