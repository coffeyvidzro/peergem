# frozen_string_literal: true

module Auth
  class PasswordsController < BaseController
    before_action :authenticate_account!, only: :enroll
    rescue_from ::Auth::Passwords::Login::InvalidCredentialsError, with: :render_invalid_credentials
    rescue_from ::Auth::EmailCodes::Verify::InvalidCodeError, with: :render_invalid_code

    def login
      result = ::Auth::Passwords::Login.call(
        transaction: auth_transaction,
        password: params.expect(:password),
        **request_context
      )

      render json: {
        user: UserSerializer.call(result.session.user),
        session: SessionSerializer.call(
          result.session,
          current_session: result.session,
          token: result.token
        )
      }
    end

    def enroll
      ::Users::EnrollPassword.call(
        user: Current.user,
        password: params.expect(:password),
        **request_context
      )
      render json: { message: "Password created successfully", has_password: true }
    end

    def forgot
      transaction, = ::Auth::Start.call(email: params.expect(:email), **request_context)
      result = ::Auth::EmailCodes::Send.call(
        transaction: transaction,
        purpose: "password_reset",
        **request_context
      )
      render json: {
        transaction_id: transaction.id,
        expires_in: (result.challenge.expires_at - Time.current).ceil,
        resend_after: result.resend_after
      }
    end

    def reset
      result = ::Auth::EmailCodes::Verify.call(
        transaction: auth_transaction,
        code: params.expect(:code),
        purpose: "password_reset",
        create_user: false,
        issue_session: false,
        **request_context
      )
      ::Users::EnrollPassword.call(
        user: result.user,
        password: params.expect(:password),
        event_type: "user.password_reset",
        **request_context
      )
      result.user.sessions.where(revoked_at: nil).update_all(revoked_at: Time.current)
      render json: { message: "Password reset successfully", has_password: true }
    end

    private

    def render_invalid_credentials
      render json: { error: "invalid_credentials" }, status: :unauthorized
    end

    def render_invalid_code
      render json: { error: "invalid_code" }, status: :unauthorized
    end
  end
end