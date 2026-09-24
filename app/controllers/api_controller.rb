# frozen_string_literal: true

class ApiController < ActionController::API
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

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

  def pundit_user
    current_session&.user
  end

  def forbidden
    render json: { error: { code: "forbidden", message: "You are not authorized to perform this action" } },
      status: :forbidden
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

  def record_not_unique
    render json: { error: { code: "conflict", message: "Resource already exists" } }, status: :conflict
  end
end
