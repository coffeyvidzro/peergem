# frozen_string_literal: true

module Sessions
  class RevokeAll
    def self.call(user:, ip_address: nil, user_agent: nil)
      now = Time.current
      count = user.sessions.active.update_all(revoked_at: now)
      Security::Events.record(
        "session.revoked_all",
        user: user,
        ip_address: ip_address,
        user_agent: user_agent,
        metadata: { count: count },
        now: now
      )
      count
    end
  end
end
