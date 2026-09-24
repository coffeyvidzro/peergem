# frozen_string_literal: true

module Auth
  class EmailController < BaseController
    rescue_from ::Auth::EmailCodes::Verify::InvalidCodeError, with: :render_invalid_code

    def send_code
      result = ::Auth::EmailCodes::Send.call(transaction: auth_transaction, **request_context)
      render_challenge(result)
    end

    def resend
      result = ::Auth::EmailCodes::Send.call(transaction: auth_transaction, **request_context)
      render_challenge(result)
    end

    def verify
      result = ::Auth::EmailCodes::Verify.call(
        transaction: auth_transaction,
        code: params.expect(:code),
        **request_context
      )

      render json: {
        user: UserSerializer.call(result.user),
        is_new_user: result.new_user,
        session: SessionSerializer.call(
          result.session,
          current_session: result.session,
          token: result.token
        )
      }
    end

    private

    def render_challenge(result)
      render json: {
        transaction_id: auth_transaction.id,
        expires_in: (result.challenge.expires_at - Time.current).ceil,
        resend_after: result.resend_after
      }
    end

    def render_invalid_code
      render json: { error: "invalid_code" }, status: :unauthorized
    end
  end
end