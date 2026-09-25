# frozen_string_literal: true

class MerchantInvitationSerializer
  def self.call(invitation, token: nil)
    {
      id: invitation.public_id,
      email: invitation.email,
      role: invitation.role,
      expires_at: invitation.expires_at.iso8601,
      created_at: invitation.created_at.iso8601,
      token: token
    }.compact
  end
end
