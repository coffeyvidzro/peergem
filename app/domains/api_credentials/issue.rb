# frozen_string_literal: true

module ApiCredentials
  class Issue
    Result = Data.define(:credential, :secret)

    def self.call(merchant:, created_by:, attributes:)
      key_id = SecureRandom.hex(12)
      secret = SecureRandom.urlsafe_base64(32, false)
      plaintext = "pgk_#{key_id}_#{secret}"

      ApiCredential.transaction do
        credential = merchant.api_credentials.create!(
          created_by: created_by,
          name: attributes.fetch(:name),
          key_id: key_id,
          secret_digest: ApiCredential.digest(secret),
          scopes: Array(attributes[:scopes]).map(&:to_s).uniq.sort,
          ip_allowlist: Array(attributes[:ip_allowlist]).map(&:to_s).uniq.sort,
          expires_at: attributes[:expires_at]
        )
        Security::Events.record(
          "api_credential.created",
          user: created_by,
          merchant: merchant,
          metadata: { api_credential_id: credential.public_id, scopes: credential.scopes }
        )
        Result.new(credential: credential, secret: plaintext)
      end
    end
  end
end
