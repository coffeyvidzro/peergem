# frozen_string_literal: true

module MerchantInvitations
  class Resend
    def self.call(invitation:, resent_by:)
      invitation.with_lock do
        raise ActiveRecord::RecordNotFound unless invitation.active?

        invitation.update!(revoked_at: Time.current)
        result = Issue.call(
          merchant: invitation.merchant,
          invited_by: resent_by,
          email: invitation.email,
          role: invitation.role
        )
        Security::Events.record(
          "merchant.invitation_resent",
          user: resent_by,
          merchant: invitation.merchant,
          metadata: { invitation_id: invitation.public_id, replacement_id: result.invitation.public_id }
        )
        result
      end
    end
  end
end
