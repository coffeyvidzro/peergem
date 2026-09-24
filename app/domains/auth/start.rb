# frozen_string_literal: true

module Auth
  class Start
    def self.call(email:)
      user = User.active.find_by(email: email)
      transaction = AuthTransaction.create!(identifier: email, user: user)
      methods = [ "email_otp" ]
      methods << "password" if user&.password_digest.present?

      [ transaction, methods ]
    end
  end
end
