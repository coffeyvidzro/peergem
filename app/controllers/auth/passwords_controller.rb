# frozen_string_literal: true

module Auth
  class PasswordsController < BaseController
    before_action :require_session!, only: :enroll

    def login
      transaction = transaction!
      return invalid_state unless transaction.started?

      user = Auth::Passwords::Login.call(transaction: transaction, password: params.require(:password))
      return invalid_credentials unless user

      render_session(user, assurance: "password")
    end

    def enroll
      return if performed?
      return password_already_enrolled if current_session.user.password_digest.present?

      current_session.user.update!(password_params)
      render json: { message: "Password enrolled" }
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: { code: "invalid_password", message: error.record.errors.full_messages.to_sentence } }, status: :unprocessable_content
    end

    def forgot
      email = normalized_email
      transaction = Auth::Passwords::Forgot.call(email: email)

      render json: { transaction_id: transaction.id, message: "If the account exists, a recovery code has been sent" }, status: :accepted
    end

    def reset
      transaction = transaction!
      user = Auth::Passwords::Reset.call(
        transaction: transaction,
        code: params.require(:code),
        **password_params
      )
      return invalid_code unless user

      render_session(user, assurance: "password")
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: { code: "invalid_password", message: error.record.errors.full_messages.to_sentence } }, status: :unprocessable_content
    end

    private

    def password_params
      password = params.require(:password)
      confirmation = params.require(:password_confirmation)
      { password: password, password_confirmation: confirmation }
    end

    def invalid_credentials
      render json: { error: { code: "invalid_credentials", message: "Email or password is incorrect" } }, status: :unauthorized
    end

    def invalid_state
      render json: { error: { code: "invalid_state", message: "Password login is not available" } }, status: :conflict
    end

    def invalid_code
      render json: { error: { code: "invalid_code", message: "The code is invalid or expired" } }, status: :unprocessable_content
    end

    def password_already_enrolled
      render json: {
        error: { code: "password_already_enrolled", message: "Use password reset to replace an existing password" }
      }, status: :conflict
    end
  end
end
