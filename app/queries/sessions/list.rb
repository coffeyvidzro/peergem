# frozen_string_literal: true

module Sessions
  class List
    def self.call(user:)
      user.sessions.active.order(created_at: :desc)
    end
  end
end
