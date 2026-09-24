# frozen_string_literal: true

module Auth
  class BaseController < ApplicationController
    rescue_from ::Auth::Errors::ExpiredTransaction, with: :render_expired_transaction
    rescue_from ::Auth::Errors::EmailDelivery, with: :render_email_delivery_error
    rescue_from ::Auth::Errors::DisposableEmail, with: :render_disposable_email
    rescue_from ::Auth::Errors::InvalidTransactionState, with: :render_invalid_transaction_state

    private

    def auth_transaction
      @auth_transaction ||= AuthTransaction.find(params.expect(:transaction_id))
    end

    def request_context
      { ip_address: request.remote_ip, user_agent: request.user_agent }
    end

    def render_expired_transaction
      render json: { error: "transaction_expired" }, status: :unprocessable_content
    end

    def render_email_delivery_error
      render json: { error: "email_delivery_unavailable" }, status: :service_unavailable
    end

    def render_invalid_transaction_state
      render json: { error: "invalid_transaction_state" }, status: :unprocessable_content
    end

    def render_disposable_email
      render json: { error: "disposable_email_not_allowed" }, status: :unprocessable_content
    end
  end
end