# frozen_string_literal: true

module Auth
  class PasswordsController < BaseController
    before_action :require_session!, only: :enroll

    def login
      transaction = transaction!
      return invalid_state unless transaction.started?

      user = transaction.user
      return invalid_credentials unless user&.authenticate(params.require(:password))

      transaction.update!(selected_method: "password")
      transaction.require_password! if transaction.started?
      transaction.authenticate!
      render_session(user, assurance: "password")
    end

    def enroll
      return if performed?

      current_session.user.update!(password_params)
      render json: { message: "Password enrolled" }
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: { code: "invalid_password", message: error.record.errors.full_messages.to_sentence } }, status: :unprocessable_content
    end

    def forgot
      email = normalized_email
      user = User.active.find_by(email: email)
      transaction = AuthTransaction.create!(identifier: email, user: user)
      issue_reset_challenge(transaction) if user

      render json: { transaction_id: transaction.id, message: "If the account exists, a recovery code has been sent" }, status: :accepted
    end

    def reset
      transaction = transaction!
      challenge = transaction.auth_challenges.active.where(purpose: "password_reset").order(created_at: :desc).first!
      return invalid_code unless challenge.verify(params.require(:code))

      user = transaction.user
      AuthTransaction.transaction do
        user.update!(password_params)
        challenge.consume!
        transaction.update!(selected_method: "password")
        transaction.require_password!
        transaction.authenticate!
        user.sessions.active.update_all(revoked_at: Time.current)
      end
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

    def issue_reset_challenge(transaction)
      code = format("%06d", SecureRandom.random_number(1_000_000))
      transaction.auth_challenges.create!(
        identifier: transaction.identifier,
        purpose: "password_reset",
        secret_hash: AuthChallenge.digest(code),
        expires_at: AuthChallenge::OTP_TTL.from_now
      )
      AuthMailer.password_reset(email: transaction.identifier, code: code).deliver_later
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
  end
end
