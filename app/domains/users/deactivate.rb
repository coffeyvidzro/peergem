# frozen_string_literal: true

module Users
  class Deactivate
    def self.call(user:)
      user.transaction do
        user.disable!
        Sessions::RevokeAll.call(user: user)
      end
    end
  end
end
