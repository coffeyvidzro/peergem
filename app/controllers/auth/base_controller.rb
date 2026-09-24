# frozen_string_literal: true

module Auth
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from ActionController::ParameterMissing, with: :bad_request

    private

    def current_session
      return @current_session if defined?(@current_session)

      scheme, token = request.authorization.to_s.split(" ", 2)
      @current_session = Session.find_by_token(token) if scheme&.casecmp?("Bearer") && token.present?
    end

    def require_session!
      return if current_session

      render json: { error: { code: "unauthorized", message: "A valid bearer token is required" } }, status: :unauthorized
    end

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
        user: user_json(user)
      }
    end

    def user_json(user)
      {
        id: user.public_id,
        email: user.email,
        email_verified: user.confirmed?,
        has_password: user.password_digest.present?,
        name: user.name,
        created_at: user.created_at.iso8601
      }
    end

    def not_found
      render json: { error: { code: "not_found", message: "Authentication transaction was not found" } }, status: :not_found
    end

    def bad_request(error)
      render json: { error: { code: "invalid_request", message: error.message } }, status: :bad_request
    end

    def record_invalid(error)
      render json: {
        error: { code: "invalid_request", message: error.record.errors.full_messages.to_sentence }
      }, status: :unprocessable_content
    end
  end
end
