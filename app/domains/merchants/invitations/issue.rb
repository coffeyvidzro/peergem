# frozen_string_literal: true

module Merchants::Invitations
  class Issue
    Result = Data.define(:invitation, :token)

    def self.call(merchant:, invited_by:, email:, role:)
      token = "#{MerchantInvitation::TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
      MerchantInvitation.transaction do
        merchant.merchant_invitations
          .where(email: email.to_s.strip.downcase, accepted_at: nil, revoked_at: nil)
          .where("expires_at <= ?", Time.current)
          .update_all(revoked_at: Time.current)
        invitation = merchant.merchant_invitations.create!(
          invited_by: invited_by,
          email: email,
          role: role,
          token_digest: MerchantInvitation.digest(token),
          expires_at: MerchantInvitation::DEFAULT_TTL.from_now
        )
        Security::Events.record(
          "merchant.invitation_created",
          user: invited_by,
          merchant: merchant,
          metadata: { invitation_id: invitation.public_id, role: role }
        )
        Result.new(invitation:, token:)
      end
    end
  end
end
