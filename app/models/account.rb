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

  # Computes standard checkout application fees (e.g., 5% + 50 Pesewas base)
  # @param amount_in_pesewas [Integer] Gross checkout price volume
  # @return [Integer] PeerGem's dynamic cut calculated in Pesewas
  def calculate_fee_in_pesewas(amount_in_pesewas)
    bps, fixed, _ = active_fee_tier
    
    gross_bd = BigDecimal(amount_in_pesewas.to_s)
    bps_bd   = BigDecimal(bps.to_s)
    fixed_bd = BigDecimal(fixed.to_s)

    # Percentage component: amount * (bps / 10,000)
    variable_cut = gross_bd * (bps_bd / BigDecimal("10000"))
    total_fee    = variable_cut + fixed_bd

    peergem_round(total_fee)
  end

  # Computes recurring billing subscription platform fees
  # @param amount_in_pesewas [Integer] Invoice billing item volume
  # @return [Integer] PeerGem's subscription platform cut in Pesewas
  def calculate_subscription_fee_in_pesewas(amount_in_pesewas)
    _, _, sub_bps = active_fee_tier
    
    gross_bd = BigDecimal(amount_in_pesewas.to_s)
    bps_bd   = BigDecimal(sub_bps.to_s)

    variable_cut = gross_bd * (bps_bd / BigDecimal("10000"))
    peergem_round(variable_cut)
  end

  # Safe programmatic modification of local balance assets
  # @param amount [Integer] Requested deduction value
  def reduce_credit_balance(amount)
    deduction = [amount, credit_balance].min
    decrement!(:credit_balance, deduction)
  end

  private

  # Decouples contractual overrides from platform base parameters
  def active_fee_tier
    [
      platform_fee_percent || DEFAULT_PLATFORM_FEE_BPS,
      platform_fee_fixed || DEFAULT_PLATFORM_FIXED_PESEWAS,
      platform_subscription_fee_percent || DEFAULT_SUBSCRIPTION_FEE_BPS
    ]
  end

  # Financial Rounding: standard rounding to nearest whole integer pesewa
  def peergem_round(value)
    value.round(0, BigDecimal::ROUND_HALF_UP).to_i
  end
end
