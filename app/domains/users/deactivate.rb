# frozen_string_literal: true

module Users
  class Deactivate
    def self.call(user:, ip_address: nil, user_agent: nil)
      user.transaction do
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
