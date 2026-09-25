# frozen_string_literal: true

class MerchantMembershipsController < ApiController
  before_action :require_session!

  def index
    return if performed?

    authorize merchant, :show?
    memberships = merchant.merchant_memberships.includes(:user).order(created_at: :asc)
    render json: { memberships: memberships.map { MerchantMembershipSerializer.call(_1) } }
  end

  def update
    return if performed?

    authorize merchant, :manage_owners?
    membership = Merchants::Memberships::Update.call(
      merchant: merchant,
      membership: find_membership,
      actor: current_session.user,
      attributes: membership_changes
    )
    render json: { membership: MerchantMembershipSerializer.call(membership) }
  end

  def destroy
    return if performed?

    authorize merchant, :manage_owners?
    Merchants::Memberships::Remove.call(
      merchant: merchant,
      membership: find_membership,
      actor: current_session.user
    )
    head :no_content
  end

  def leave
    return if performed?

    authorize merchant, :show?
    membership = merchant.merchant_memberships.active.find_by!(user: current_session.user)
    Merchants::Memberships::Remove.call(
      merchant: merchant,
      membership: membership,
      actor: current_session.user,
      leaving: true
    )
    head :no_content
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def find_membership
    merchant.merchant_memberships.find(MerchantMembership.id_from_public_id!(params.require(:membership_id)))
  end

  def membership_changes
    attributes = params.require(:membership)
    {}.tap do |changes|
      changes[:role] = attributes[:role] if attributes.key?(:role)
      changes[:status] = attributes[:status] if attributes.key?(:status)
    end
  end
end
