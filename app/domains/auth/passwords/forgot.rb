# frozen_string_literal: true

module Auth
  module Passwords
    class Forgot
      def self.call(email:)
        user = User.active.find_by(email: email)
        transaction = AuthTransaction.create!(identifier: email, user: user)
        Challenges::Issue.call(transaction: transaction, purpose: "password_reset") if user
        transaction
      end
    end
  end
end
