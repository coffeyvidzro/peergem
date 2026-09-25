# frozen_string_literal: true

class MerchantsController < ApiController
  before_action :require_session!

  def index
    return if performed?

    memberships = current_session.user.merchant_memberships.active.includes(:merchant).order(created_at: :asc)
    render json: {
      merchants: memberships.map { |membership| MerchantSerializer.call(membership.merchant, membership:) }
    }
  end

  def create
    return if performed?

    merchant = Merchants::Create.call(user: current_session.user, attributes: merchant_params)
    render json: {
      merchant: MerchantSerializer.call(merchant, membership: merchant.merchant_memberships.first)
    }, status: :created
  end

  def show
    return if performed?

    authorize merchant
    render json: { merchant: MerchantSerializer.call(merchant, membership: policy(merchant).membership) }
  end

  def update
    return if performed?

    authorize merchant
    merchant.transaction do
      merchant.update!(merchant_update_params)
      Security::Events.record(
        "merchant.updated",
        user: current_session.user,
        merchant: merchant,
        metadata: { changed_fields: merchant.previous_changes.keys - %w[updated_at] }
      )
    end
    render json: { merchant: MerchantSerializer.call(merchant) }
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def merchant_params
    params.require(:merchant).permit(:name, :slug, :email, :website, :country_code, :timezone, :account_type)
  end

  def merchant_update_params
    params.require(:merchant).permit(:name, :email, :website, :timezone)
  end
end
