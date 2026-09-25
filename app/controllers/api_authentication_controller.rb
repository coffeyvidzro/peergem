# frozen_string_literal: true

class ApiAuthenticationController < ApiController
  def show
    require_api_credential!
    return if performed?

    render json: {
      api_credential: ApiCredentialSerializer.call(current_api_credential),
      merchant: MerchantSerializer.call(current_api_credential.merchant)
    }
  end
end
