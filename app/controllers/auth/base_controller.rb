# frozen_string_literal: true

module Auth
  class BaseController < ApiController
    private

    def normalized_email
      params.require(:email).to_s.strip.downcase
    end

    def transaction!
      transaction = AuthTransaction.find(params.require(:transaction_id))
      raise ActiveRecord::RecordNotFound if transaction.expired? || transaction.authenticated?

      transaction
    end

    def render_session(user, assurance:)
      session, token = Session.issue(
        user: user,
        assurance: assurance,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      render json: {
        token: token,
        token_type: "Bearer",
        expires_at: session.expires_at.iso8601,
        user: UserSerializer.new(user).as_json
      }
    end

    def not_found
      render json: { error: { code: "not_found", message: "Authentication transaction was not found" } }, status: :not_found
    end
  end
end
