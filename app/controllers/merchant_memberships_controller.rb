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
    membership = merchant.with_lock do
      record = find_membership
      changes = membership_changes
      prevent_last_owner_change!(record, changes)
      record.role = changes[:role] if changes.key?(:role)
      record.status = changes[:status] if changes.key?(:status)
      record.save!
      Security::Events.record(
        "merchant.membership_updated",
        user: current_session.user,
        merchant: merchant,
        metadata: { membership_id: record.public_id, role: record.role, status: record.status }
      )
      record
    end
    render json: { membership: MerchantMembershipSerializer.call(membership) }
  end

  def destroy
    return if performed?

    authorize merchant, :manage_owners?
    merchant.with_lock do
      membership = find_membership
      prevent_last_owner_change!(membership, nil)
      membership.destroy!
      Security::Events.record(
        "merchant.membership_removed",
        user: current_session.user,
        merchant: merchant,
        metadata: { membership_id: membership.public_id }
      )
    end
    head :no_content
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def find_membership
    merchant.merchant_memberships.find(MerchantMembership.id_from_public_id!(params.require(:id)))
  end

  def membership_changes
    attributes = params.require(:membership)
    {}.tap do |changes|
      changes[:role] = attributes[:role] if attributes.key?(:role)
      changes[:status] = attributes[:status] if attributes.key?(:status)
    end
  end

  def prevent_last_owner_change!(membership, changes)
    return unless membership.role == "owner" && membership.status == "active"

    remains_owner = changes && changes.fetch(:role, membership.role) == "owner" &&
      changes.fetch(:status, membership.status) == "active"
    return if remains_owner
    return if merchant.merchant_memberships.active.where(role: "owner").where.not(id: membership.id).exists?

    raise Pundit::NotAuthorizedError, "A merchant must retain an active owner"
  end
end
