# frozen_string_literal: true

# Single-node Redlock.

redlock_pool = ConnectionPool.new(
  size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  timeout: 2
) do
  Redis.new(url: Rails.application.config.x.redis_url.sub(%r{/\d+\z}, "/2"))
end

Rails.application.config.x.redlock = Redlock::Client.new(
  [ redlock_pool ],
  retry_count: 3,
  retry_delay: 200,
  retry_jitter: 100
)
