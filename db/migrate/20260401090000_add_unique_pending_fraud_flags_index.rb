# One pending fraud flag per (provider, flag_type); resolved/dismissed rows may repeat.
class AddUniquePendingFraudFlagsIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :fraud_flags, %i[provider_id flag_type],
              unique: true,
              where: "status = 'pending'",
              name: "index_fraud_flags_unique_pending_provider_flag_type"
  end
end
