# frozen_string_literal: true

module Auth
  module Passwords
    class Change
      InvalidCurrentPasswordError = Class.new(StandardError)

      def self.call(user:, current_session:, current_password:, password:, password_confirmation:, ip_address:, user_agent:)
        raise InvalidCurrentPasswordError unless user.authenticate(current_password)

        user.transaction do
          user.update!(password: password, password_confirmation: password_confirmation, failed_attempts: 0)
          Sessions::RevokeAll.call(
            user: user,
            except: current_session,
            ip_address: ip_address,
            user_agent: user_agent
          )
          Security::Events.record(
            "user.password_changed",
            user: user,
            ip_address: ip_address,
            user_agent: user_agent
          )
        end
      end
    end
  end
end
