# frozen_string_literal: true

class ApiKeysController < ApiController
  before_action :require_session!

  def index
    return if performed?

    authorize merchant, :manage_api_keys?
    api_keys = merchant.api_keys.order(created_at: :desc)
    render json: { api_keys: api_keys.map { ApiKeySerializer.call(_1) } }
  end

  def create
    return if performed?

    authorize merchant, :manage_api_keys?
    result = Merchants::ApiKeys::Issue.call(
      merchant: merchant,
      created_by: current_session.user,
      attributes: api_key_params
    )
    render json: {
      api_key: ApiKeySerializer.call(result.api_key, secret: result.secret)
    }, status: :created
  end

  def destroy
    return if performed?

    authorize merchant, :manage_api_keys?
    api_key = find_api_key
    revoke!(api_key)
    head :no_content
  end

  def update
    return if performed?

    authorize merchant, :manage_api_keys?
    api_key = find_api_key
    api_key.transaction do
      api_key.update!(name: params.require(:api_key).require(:name))
      Security::Events.record(
        "api_key.renamed",
        user: current_session.user,
        merchant: merchant,
        metadata: { api_key_id: api_key.public_id }
      )
    end
    render json: { api_key: ApiKeySerializer.call(api_key) }
  end

  def rotate
    return if performed?

    authorize merchant, :manage_api_keys?
    result = Merchants::ApiKeys::Rotate.call(api_key: find_api_key, rotated_by: current_session.user)
    render json: {
      api_key: ApiKeySerializer.call(result.api_key, secret: result.secret)
    }, status: :created
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def find_api_key
    merchant.api_keys.find(ApiKey.id_from_public_id!(params.require(:api_key_id)))
  end

  def api_key_params
    permitted = params.require(:api_key).permit(:name, :expires_at, scopes: [], ip_allowlist: [])
    permitted.to_h.symbolize_keys
  end

  def revoke!(api_key)
    api_key.with_lock do
      return if api_key.revoked_at?

      api_key.update!(revoked_at: Time.current)
      Security::Events.record(
        "api_key.revoked",
        user: current_session.user,
        merchant: merchant,
        metadata: { api_key_id: api_key.public_id }
      )
    end
  end
end
