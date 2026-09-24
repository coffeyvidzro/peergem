# frozen_string_literal: true

module Auth
  module Challenges
    class Verify
      def self.call(transaction:, code:)
        transaction.with_lock do
          return unless transaction.otp_sent? && !transaction.expired?

          challenge = transaction.auth_challenges.active.where(purpose: "email_otp").order(created_at: :desc).first!
          return unless challenge.verify(code)

          user = transaction.user || User.create!(email: transaction.identifier)
          challenge.consume!
          user.confirm! unless user.confirmed?
          transaction.update!(user: user)
          transaction.verify_otp!
          transaction.authenticate!
          user
        end
      end
    end
  end
end
