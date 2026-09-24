# frozen_string_literal: true

module Auth
  class TransactionsController < BaseController
    def create
      transaction, methods = ::Auth::Start.call(email: params.expect(:email), **request_context)

      render json: {
        transaction_id: transaction.id,
        methods: methods,
        expires_in: (transaction.expires_at - Time.current).ceil
      }
    end
  end
end