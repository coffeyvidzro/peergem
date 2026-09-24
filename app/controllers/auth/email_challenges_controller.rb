# frozen_string_literal: true

module Auth
  class EmailChallengesController < BaseController
    def create
      transaction = transaction!
      challenge = Auth::Challenges::Send.call(transaction: transaction)
      return conflict("OTP has already been sent") unless challenge

      render_challenge(challenge, :created)
    end

    def resend
      transaction = transaction!
      challenge, cooling_down = Auth::Challenges::Resend.call(transaction: transaction)
      return cooldown(cooling_down) if cooling_down

      render_challenge(challenge, :ok)
    end

    def verify
      transaction = transaction!
      user = Auth::Challenges::Verify.call(transaction: transaction, code: params.require(:code))
      return invalid_code unless user

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
