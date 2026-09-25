# frozen_string_literal: true

module Merchants
  class Create
    def self.call(user:, attributes:)
      Merchant.transaction do
        merchant = Merchant.create!(attributes)
        merchant.merchant_memberships.create!(
          user: user,
          role: "owner",
          status: "active",
          joined_at: Time.current
        )
        Security::Events.record("merchant.created", user: user, merchant: merchant)
        merchant
      end
    end
  end
end
