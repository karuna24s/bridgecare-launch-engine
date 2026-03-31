# frozen_string_literal: true

class FraudFlag < ApplicationRecord
  belongs_to :provider

  validates :flag_type, presence: true
  validates :status, presence: true
end
