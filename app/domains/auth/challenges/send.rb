# frozen_string_literal: true

module Auth
  module Challenges
    class Send
      def self.call(transaction:)
        transaction.with_lock do
          return unless transaction.started? && !transaction.expired?

          challenge = Issue.call(transaction: transaction, purpose: "email_otp")
          transaction.update!(selected_method: "otp")
          transaction.send_otp!
          challenge
        end
      end
    end
  end
end
