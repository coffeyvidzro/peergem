# frozen_string_literal: true

module Sessions
  class RevokeAll
    def self.call(user:, except: nil, ip_address: nil, user_agent: nil)
      now = Time.current
      sessions = user.sessions.active
      sessions = sessions.where.not(id: except.id) if except
      count = sessions.update_all(revoked_at: now)
      Security::Events.record(
        except ? "session.revoked_others" : "session.revoked_all",
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
