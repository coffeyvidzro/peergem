# frozen_string_literal: true

module Merchants::ApiKeys
  class Issue
    Result = Data.define(:api_key, :secret)

    def self.call(merchant:, created_by:, attributes:)
      key_id = SecureRandom.hex(12)
      secret = SecureRandom.urlsafe_base64(32, false)
      plaintext = "pgk_#{key_id}_#{secret}"

      ApiKey.transaction do
        api_key = merchant.api_keys.create!(
          created_by: created_by,
          name: attributes.fetch(:name),
          key_id: key_id,
          secret_digest: ApiKey.digest(secret),
          scopes: Array(attributes[:scopes]).map(&:to_s).uniq.sort,
          ip_allowlist: Array(attributes[:ip_allowlist]).map(&:to_s).uniq.sort,
          expires_at: attributes[:expires_at]
        )
        Security::Events.record(
          "api_key.created",
          user: created_by,
          merchant: merchant,
          metadata: { api_key_id: api_key.public_id, scopes: api_key.scopes }
        )
        Result.new(api_key: api_key, secret: plaintext)
      end
    end
  end
end
