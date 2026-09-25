# frozen_string_literal: true

class ApiKeySerializer
  def self.call(api_key, secret: nil)
    {
      id: api_key.public_id,
      name: api_key.name,
      scopes: api_key.scopes,
      ip_allowlist: api_key.ip_allowlist,
      expires_at: api_key.expires_at&.iso8601,
      last_used_at: api_key.last_used_at&.iso8601,
      last_used_ip: api_key.last_used_ip&.to_s,
      revoked_at: api_key.revoked_at&.iso8601,
      created_at: api_key.created_at.iso8601,
      secret: secret
    }.compact
  end
end
