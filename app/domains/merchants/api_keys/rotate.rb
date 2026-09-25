# frozen_string_literal: true

module Merchants::ApiKeys
  class Rotate
    def self.call(api_key:, rotated_by:)
      api_key.with_lock do
        raise ActiveRecord::RecordNotFound unless api_key.active?

        result = Issue.call(
          merchant: api_key.merchant,
          created_by: rotated_by,
          attributes: {
            name: api_key.name,
            scopes: api_key.scopes,
            ip_allowlist: api_key.ip_allowlist,
            expires_at: api_key.expires_at
          }
        )
        api_key.update!(revoked_at: Time.current, replaced_by: result.api_key)
        Security::Events.record(
          "api_key.rotated",
          user: rotated_by,
          merchant: api_key.merchant,
          metadata: {
            api_key_id: api_key.public_id,
            replacement_id: result.api_key.public_id
          }
        )
        result
      end
    end
  end
end
