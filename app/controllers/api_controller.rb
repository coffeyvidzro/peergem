# frozen_string_literal: true

class ApiController < ActionController::API
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

  def not_found
    render json: { error: { code: "not_found", message: "Resource was not found" } }, status: :not_found
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
