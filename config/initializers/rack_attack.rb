# frozen_string_literal: true

require "openssl"

# Keep tests hermetic while sharing the deployed Redis service across web
# processes for globally consistent request limits.
Rack::Attack.cache.store = if Rails.env.test?
  ActiveSupport::Cache::MemoryStore.new
else
  ActiveSupport::Cache::RedisCacheStore.new(
    url: Rails.application.config.x.redis_url,
    namespace: "peergem:rack-attack"
  )
end

Rack::Attack.throttle("requests/ip", limit: 300, period: 5.minutes) do |request|
  request.ip unless request.path == "/up"
end

Rack::Attack.throttle("authentication/ip", limit: 20, period: 1.minute) do |request|
  request.ip if request.path.start_with?("/auth/") && request.post?
end

# Hash identifiers before they become Redis keys. This limits abuse across
# rotating IP addresses without persisting email addresses or transaction IDs.
throttle_secret = ENV["RACK_ATTACK_THROTTLE_SECRET"].presence ||
  Rails.application.key_generator.generate_key("rack-attack-identifiers", 32)
identifier_digest = lambda do |identifier|
  normalized = identifier.to_s.strip.downcase
  OpenSSL::HMAC.hexdigest("SHA256", throttle_secret, normalized) if normalized.present?
end

Rack::Attack.throttle("authentication/email", limit: 10, period: 10.minutes) do |request|
  if request.post? && [ "/auth/start", "/auth/password/forgot" ].include?(request.path)
    identifier_digest.call(request.params["email"])
  end
end

Rack::Attack.throttle("authentication/transaction", limit: 10, period: 10.minutes) do |request|
  transaction_paths = %w[
    /auth/email/send
    /auth/email/resend
    /auth/email/verify
    /auth/password/login
    /auth/password/reset
  ]
  identifier_digest.call(request.params["transaction_id"]) if request.post? && transaction_paths.include?(request.path)
end

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = request.env.fetch("rack.attack.match_data", {})[:period]
  headers = { "Content-Type" => "application/json" }
  headers["Retry-After"] = retry_after.to_i.to_s if retry_after

  [ 429, headers, [ { error: "rate_limit_exceeded" }.to_json ] ]
end
