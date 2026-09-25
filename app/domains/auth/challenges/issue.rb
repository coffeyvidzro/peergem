# frozen_string_literal: true

module Auth
  module Challenges
    class Issue
      MAILERS = {
        "email_otp" => :otp,
        "password_reset" => :password_reset
      }.freeze

      def self.call(transaction:, purpose:)
        mailer = MAILERS.fetch(purpose)
        code = format("%06d", SecureRandom.random_number(1_000_000))
        challenge = transaction.auth_challenges.create!(
          identifier: transaction.identifier,
          purpose: purpose,
          secret_hash: AuthChallenge.digest(code),
          expires_at: AuthChallenge::OTP_TTL.from_now
        )
        AuthMailer.public_send(mailer, email: transaction.identifier, code: code).deliver_later
        challenge
      end
    end
  end
end
