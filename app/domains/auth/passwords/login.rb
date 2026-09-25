# frozen_string_literal: true

module Auth
  module Passwords
    class Login
      DUMMY_PASSWORD_DIGEST = BCrypt::Password.create(SecureRandom.hex(32), cost: BCrypt::Engine.cost)

      def self.call(transaction:, password:, ip_address: nil, user_agent: nil)
        transaction.with_lock do
          return unless transaction.started? && !transaction.expired?

          user = transaction.user
          authenticated = if user&.password_digest.present?
            user.authenticate(password)
          else
            BCrypt::Password.new(DUMMY_PASSWORD_DIGEST).is_password?(password)
            false
          end
          unless authenticated
            user&.increment!(:failed_attempts)
            Security::Events.record(
              "authentication.failed",
              user: user,
              ip_address: ip_address,
              user_agent: user_agent,
              metadata: { method: "password", failed_attempts: user&.failed_attempts }
            )
            return false
          end

          user.update!(failed_attempts: 0) if user.failed_attempts.positive?
          transaction.update!(selected_method: "password")
          transaction.require_password!
          transaction.authenticate!
          Security::Events.record(
            "authentication.succeeded",
            user: user,
            ip_address: ip_address,
            user_agent: user_agent,
            metadata: { method: "password" }
          )
          user
        end
      end
    end
  end
end
