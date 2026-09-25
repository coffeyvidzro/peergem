# frozen_string_literal: true

require "bigdecimal"

module Accounts
  class Fees
    def self.checkout(account:, amount_in_pesewas:)
      bps = account.platform_fee_percent || Account::DEFAULT_PLATFORM_FEE_BPS
      fixed = account.platform_fee_fixed || Account::DEFAULT_PLATFORM_FIXED_PESEWAS

      variable = BigDecimal(amount_in_pesewas.to_s) * (BigDecimal(bps.to_s) / BigDecimal("10000"))
      (variable + BigDecimal(fixed.to_s)).round(0, BigDecimal::ROUND_HALF_UP).to_i
    end

    def self.subscription(account:, amount_in_pesewas:)
      bps = account.platform_subscription_fee_percent || Account::DEFAULT_SUBSCRIPTION_FEE_BPS
      variable = BigDecimal(amount_in_pesewas.to_s) * (BigDecimal(bps.to_s) / BigDecimal("10000"))
      variable.round(0, BigDecimal::ROUND_HALF_UP).to_i
    end
  end
end
