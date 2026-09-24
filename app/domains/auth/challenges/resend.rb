# frozen_string_literal: true

module Auth
  module Challenges
    class Resend
      def self.call(transaction:)
        transaction.with_lock do
          raise ActiveRecord::RecordNotFound if transaction.expired? || transaction.authenticated?

          challenge = transaction.auth_challenges.where(purpose: "email_otp").order(created_at: :desc).first!
          return [ nil, challenge ] if challenge.resend_available_at.future?

          challenge.consume! unless challenge.consumed?
          [ Issue.call(transaction: transaction, purpose: "email_otp"), nil ]
        end
      end
    end
  end
end
