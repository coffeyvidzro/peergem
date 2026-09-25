# frozen_string_literal: true

class ApiCredentialSerializer
  def self.call(credential, secret: nil)
    {
      id: credential.public_id,
      name: credential.name,
      mode: credential.mode,
      scopes: credential.scopes,
      ip_allowlist: credential.ip_allowlist,
      expires_at: credential.expires_at&.iso8601,
      last_used_at: credential.last_used_at&.iso8601,
      last_used_ip: credential.last_used_ip&.to_s,
      revoked_at: credential.revoked_at&.iso8601,
      created_at: credential.created_at.iso8601,
      secret: secret
    }.compact
  end
end
