# frozen_string_literal: true

Rails.application.config.x.redlock = Redlock::Client.new(
  [ Rails.application.config.x.redis_url ]
)

# Redis locks coordinate distributed work; PostgreSQL constraints and
# transactions must still enforce financial correctness and idempotency.
