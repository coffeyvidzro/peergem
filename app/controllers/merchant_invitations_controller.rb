# frozen_string_literal: true

class MerchantInvitationsController < ApiController
  before_action :require_session!
  rescue_from Merchants::Invitations::Accept::EmailMismatchError, with: :email_mismatch

  def index
    return if performed?

    authorize merchant, :manage_members?
    invitations = merchant.merchant_invitations.active.order(created_at: :desc)
    render json: { invitations: invitations.map { MerchantInvitationSerializer.call(_1) } }
  end

  def create
    return if performed?

    authorize merchant, :manage_members?
    attributes = invitation_params
    authorize merchant, :manage_owners? if attributes[:role] == "admin"
    result = Merchants::Invitations::Issue.call(
      merchant: merchant,
      invited_by: current_session.user,
      **attributes
    )
    render json: {
      invitation: MerchantInvitationSerializer.call(result.invitation, token: result.token)
    }, status: :created
  end

  def destroy
    return if performed?

    authorize merchant, :manage_members?
    invitation = merchant.merchant_invitations.active.find(invitation_id)
    invitation.update!(revoked_at: Time.current)
    Security::Events.record(
      "merchant.invitation_revoked",
      user: current_session.user,
      merchant: merchant,
      metadata: { invitation_id: invitation.public_id }
    )
    head :no_content
  end

  def accept
    return if performed?

    membership = Merchants::Invitations::Accept.call(
      user: current_session.user,
      token: params.require(:token)
    )
    render json: { membership: MerchantMembershipSerializer.call(membership) }, status: :created
  end

  def resend
    return if performed?

    authorize merchant, :manage_members?
    invitation = merchant.merchant_invitations.active.find(invitation_id)
    authorize merchant, :manage_owners? if invitation.role == "admin"
    result = Merchants::Invitations::Resend.call(
      invitation: invitation,
      resent_by: current_session.user
    )
    render json: {
      invitation: MerchantInvitationSerializer.call(result.invitation, token: result.token)
    }, status: :created
  end

  private

  def merchant
    @merchant ||= Merchant.find_by_public_id!(params.require(:merchant_id))
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role).to_h.symbolize_keys
  end

  def invitation_id
    MerchantInvitation.id_from_public_id!(params.require(:invitation_id))
  end

  def email_mismatch
    render json: { error: { code: "invitation_email_mismatch", message: "Invitation does not belong to this user" } },
      status: :forbidden
  end
end
