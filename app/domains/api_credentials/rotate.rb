# frozen_string_literal: true

module ApiCredentials
  class Rotate
    def self.call(credential:, rotated_by:)
      credential.with_lock do
        raise ActiveRecord::RecordNotFound unless credential.active?

        result = Issue.call(
          merchant: credential.merchant,
          created_by: rotated_by,
          attributes: {
            name: credential.name,
            mode: credential.mode,
            scopes: credential.scopes,
            ip_allowlist: credential.ip_allowlist,
            expires_at: credential.expires_at
          }
        )
        credential.update!(revoked_at: Time.current, replaced_by: result.credential)
        Security::Events.record(
          "api_credential.rotated",
          user: rotated_by,
          merchant: credential.merchant,
          metadata: {
            api_credential_id: credential.public_id,
            replacement_id: result.credential.public_id
          }
        )
        result
      end
    end
  end
end
