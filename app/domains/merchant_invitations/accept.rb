# frozen_string_literal: true

module MerchantInvitations
  class Accept
    EmailMismatchError = Class.new(StandardError)

    def self.call(user:, token:)
      invitation = MerchantInvitation.find_by_token!(token)
      raise EmailMismatchError unless invitation.email.casecmp?(user.email)

      invitation.with_lock do
        raise ActiveRecord::RecordNotFound unless invitation.active?

        membership = invitation.merchant.merchant_memberships.create!(
          user: user,
          role: invitation.role,
          status: "active",
          invited_by: invitation.invited_by,
          joined_at: Time.current
        )
        invitation.update!(accepted_at: Time.current)
        Security::Events.record(
          "merchant.invitation_accepted",
          user: user,
          merchant: invitation.merchant,
          metadata: { invitation_id: invitation.public_id, membership_id: membership.public_id }
        )
        membership
      end
    end
  end
end
