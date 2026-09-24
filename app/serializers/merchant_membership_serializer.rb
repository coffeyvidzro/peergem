# frozen_string_literal: true

class MerchantMembershipSerializer
  def self.call(membership)
    {
      id: membership.public_id,
      role: membership.role,
      status: membership.status,
      joined_at: membership.joined_at&.iso8601,
      user: UserSerializer.new(membership.user).as_json
    }
  end
end
