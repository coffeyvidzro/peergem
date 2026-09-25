# frozen_string_literal: true

module Auth
  module Passwords
    class Reset
      def self.call(transaction:, code:, password:, password_confirmation:)
        transaction.with_lock do
          return unless !transaction.expired? && !transaction.authenticated?

          challenge = transaction.auth_challenges.active.where(purpose: "password_reset").order(created_at: :desc).first!
          return unless challenge.verify(code)

          user = transaction.user
          user.update!(password: password, password_confirmation: password_confirmation)
          challenge.consume!
          transaction.update!(selected_method: "password")
          transaction.require_password!
          transaction.authenticate!
          Sessions::RevokeAll.call(user: user)
          user
        end
      end
    end
  end
end
