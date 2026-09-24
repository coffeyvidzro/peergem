# frozen_string_literal: true

module Sentry
  module PiiScrubber
    REDACTED = "[REDACTED]"

    PII_KEYS = %w[
      email phone momo_number msisdn ghana_card ghana_card_number
      card_pan card_number cvv cvc pin otp otp_code password
      password_confirmation token secret authorization cookie api_key
      bvn bank_account ssn
    ].freeze

    def self.scrub(hash)
      return hash unless hash.is_a?(Hash)

      hash.each do |k, v|
        if pii_key?(k)
          hash[k] = REDACTED
        else
          scrub(v)
        end
      end
      hash
    end

    def self.pii_key?(key)
      normalized = key.to_s.downcase
      PII_KEYS.any? { |pii| normalized.include?(pii) }
    end
  end
end
