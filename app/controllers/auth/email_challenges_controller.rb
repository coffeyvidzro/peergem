# frozen_string_literal: true

module Auth
  class EmailChallengesController < BaseController
    def create
      transaction = transaction!
      return conflict("OTP has already been sent") unless transaction.started?

      challenge = Auth::Challenges::Issue.call(transaction: transaction, purpose: "email_otp")
      transaction.update!(selected_method: "otp")
      transaction.send_otp!
      render_challenge(challenge, :created)
    end

    def resend
      transaction = transaction!
      challenge = transaction.auth_challenges.where(purpose: "email_otp").order(created_at: :desc).first!
      return cooldown(challenge) if challenge.resend_available_at.future?

      challenge.consume! unless challenge.consumed?
      render_challenge(Auth::Challenges::Issue.call(transaction: transaction, purpose: "email_otp"), :ok)
    end

    def verify
      transaction = transaction!
      challenge = transaction.auth_challenges.active.where(purpose: "email_otp").order(created_at: :desc).first!
      return invalid_code unless challenge.verify(params.require(:code))

      user = transaction.user || User.create!(email: transaction.identifier)
      AuthTransaction.transaction do
        challenge.consume!
        user.confirm! unless user.confirmed?
        transaction.update!(user: user)
        transaction.verify_otp!
        transaction.authenticate!
      end
      render_session(user, assurance: "otp")
    end

    private

    def render_challenge(challenge, status)
      render json: {
        transaction_id: challenge.auth_transaction_id,
        expires_at: challenge.expires_at.iso8601,
        resend_available_at: challenge.resend_available_at.iso8601
      }, status: status
    end

    def cooldown(challenge)
      render json: {
        error: { code: "cooldown", message: "Please wait before requesting another code" },
        resend_available_at: challenge.resend_available_at.iso8601
      }, status: :too_many_requests
    end

    def invalid_code
      render json: { error: { code: "invalid_code", message: "The code is invalid or expired" } }, status: :unprocessable_content
    end

    def conflict(message)
      render json: { error: { code: "invalid_state", message: message } }, status: :conflict
    end
  end
end
