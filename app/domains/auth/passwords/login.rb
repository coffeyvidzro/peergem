# frozen_string_literal: true

module Auth
  module Passwords
    class Login
      DUMMY_PASSWORD_DIGEST = BCrypt::Password.create(SecureRandom.hex(32), cost: BCrypt::Engine.cost)

      def self.call(transaction:, password:)
        transaction.with_lock do
          return unless transaction.started? && !transaction.expired?

          user = transaction.user
          authenticated = if user&.password_digest.present?
            user.authenticate(password)
          else
            BCrypt::Password.new(DUMMY_PASSWORD_DIGEST).is_password?(password)
            false
          end
          return false unless authenticated

          transaction.update!(selected_method: "password")
          transaction.require_password!
          transaction.authenticate!
          user
        end
      end
    end
  end
end
