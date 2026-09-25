# frozen_string_literal: true

module Auth
  class Start
    AUTHENTICATION_METHODS = %w[email_otp password].freeze

    def self.call(email:)
      user = User.active.find_by(email: email)
      transaction = AuthTransaction.create!(identifier: email, user: user)

      # Keep the response identical for registered and unregistered addresses.
      # Method availability must not become an account-enumeration oracle.
      [ transaction, AUTHENTICATION_METHODS ]
    end
  end
end
