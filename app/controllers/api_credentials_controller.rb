# frozen_string_literal: true

class ApiCredentialsController < ApiController
  before_action :require_session!

  def index
    return if performed?

    authorize merchant, :manage_api_credentials?
    credentials = merchant.api_credentials.order(created_at: :desc)
    render json: { api_credentials: credentials.map { ApiCredentialSerializer.call(_1) } }
  end

  def create
    return if performed?

    authorize merchant, :manage_api_credentials?
    result = ApiCredentials::Issue.call(
      merchant: merchant,
      created_by: current_session.user,
      attributes: credential_params
    )
    render json: {
      api_credential: ApiCredentialSerializer.call(result.credential, secret: result.secret)
    }, status: :created
  end

  def destroy
    return if performed?

    authorize merchant, :manage_api_credentials?
    credential = find_credential
    revoke!(credential)
    head :no_content
  end

  def rotate
    return if performed?

    authorize merchant, :manage_api_credentials?
    result = ApiCredentials::Rotate.call(credential: find_credential, rotated_by: current_session.user)
    render json: {
      api_credential: ApiCredentialSerializer.call(result.credential, secret: result.secret)
    }, status: :created
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def find_credential
    merchant.api_credentials.find(ApiCredential.id_from_public_id!(params.require(:id)))
  end

  def credential_params
    permitted = params.require(:api_credential).permit(:name, :expires_at, scopes: [], ip_allowlist: [])
    permitted.to_h.symbolize_keys
  end

  def revoke!(credential)
    credential.with_lock do
      return if credential.revoked_at?

      credential.update!(revoked_at: Time.current)
      Security::Events.record(
        "api_credential.revoked",
        user: current_session.user,
        merchant: merchant,
        metadata: { api_credential_id: credential.public_id }
      )
    end
  end
end
