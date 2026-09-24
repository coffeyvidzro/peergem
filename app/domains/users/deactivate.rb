# frozen_string_literal: true

module Users
  class Deactivate
    ConfirmationRequiredError = Class.new(StandardError)
    ReauthenticationRequiredError = Class.new(StandardError)
    MerchantOwnershipRequiredError = Class.new(StandardError)

    def self.call(user:, confirmation:, password: nil, ip_address: nil, user_agent: nil)
      raise ConfirmationRequiredError unless confirmation == "DEACTIVATE"
      raise ReauthenticationRequiredError if user.password_digest.present? && !user.authenticate(password)

      user.transaction do
        sole_owner = user.merchant_memberships.active.where(role: "owner").any? do |membership|
          !membership.merchant.merchant_memberships.active.where(role: "owner").where.not(user: user).exists?
        end
        raise MerchantOwnershipRequiredError if sole_owner

        user.disable!
        Sessions::RevokeAll.call(user: user, ip_address: ip_address, user_agent: user_agent)
        Security::Events.record(
          "user.deactivated",
          user: user,
          ip_address: ip_address,
          user_agent: user_agent
        )
      end
    end
  end
end
