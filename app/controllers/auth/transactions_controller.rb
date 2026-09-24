# frozen_string_literal: true

module Auth
  class TransactionsController < BaseController
    def create
      email = normalized_email
      user = User.active.find_by(email: email)
      transaction = AuthTransaction.create!(identifier: email, user: user)

      render json: {
        transaction_id: transaction.id,
        expires_at: transaction.expires_at.iso8601,
        methods: authentication_methods(user)
      }, status: :created
    end

    private

    def authentication_methods(user)
      methods = [ "email_otp" ]
      methods << "password" if user&.password_digest.present?
      methods
    end
  end
end
