# frozen_string_literal: true

class MerchantSerializer
  def self.call(merchant, membership: nil)
    {
      id: merchant.public_id,
      name: merchant.name,
      slug: merchant.slug,
      email: merchant.email,
      website: merchant.website,
      country_code: merchant.country_code,
      timezone: merchant.timezone,
      status: merchant.status,
      account_type: merchant.account_type,
      role: membership&.role,
      created_at: merchant.created_at.iso8601
    }.compact
  end
end
