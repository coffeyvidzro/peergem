# frozen_string_literal: true

require "bigdecimal"

class Account < ApplicationRecord
  # Structural Associations (Links back to your Merchant profile migration)
  belongs_to :merchant

  # Configuration Core Fallbacks
  DEFAULT_PLATFORM_FEE_BPS       = 500  # 500 Basis Points = 5.00%
  DEFAULT_PLATFORM_FIXED_PESEWAS = 50   # 50 Pesewas = GH¢ 0.50
  DEFAULT_SUBSCRIPTION_FEE_BPS   = 400  # 400 Basis Points = 4.00% for Billing items

  # Multi-Tenant & Mathematical Validations matching Rails 8.1 schema
  validates :currency, presence: true, length: { is: 3 }
  validates :credit_balance, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payout_delay, presence: true

  # Fee calculations are merchant-account configuration, not ledger balances.
  def calculate_fee_in_pesewas(amount_in_pesewas)
    Accounts::Fees.checkout(account: self, amount_in_pesewas: amount_in_pesewas)
  end

  def calculate_subscription_fee_in_pesewas(amount_in_pesewas)
    Accounts::Fees.subscription(account: self, amount_in_pesewas: amount_in_pesewas)
  end
end
