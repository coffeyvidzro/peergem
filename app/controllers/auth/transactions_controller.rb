# frozen_string_literal: true

module Auth
  class TransactionsController < BaseController
    def create
      email = normalized_email
      transaction, methods = Auth::Start.call(email: email)

      render json: {
        transaction_id: transaction.id,
        expires_at: transaction.expires_at.iso8601,
        methods: methods
      }, status: :created
    end

  end
end
