# frozen_string_literal: true

module Sessions
  class RevokeAll
    def self.call(user:)
      user.sessions.active.update_all(revoked_at: Time.current)
    end
  end
end
