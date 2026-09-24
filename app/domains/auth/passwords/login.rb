# frozen_string_literal: true

module Auth
  module Passwords
    class Login
      def self.call(transaction:, password:)
        transaction.with_lock do
          return unless transaction.started? && !transaction.expired?

          user = transaction.user
          return false unless user&.authenticate(password)

          transaction.update!(selected_method: "password")
          transaction.require_password!
          transaction.authenticate!
          user
        end
      end
    end
  end
end
