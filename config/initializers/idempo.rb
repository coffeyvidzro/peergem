# frozen_string_literal: true

redis_url = Rails.application.config.x.redis_url

idempo_redis_pool = ConnectionPool.new(
  size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  timeout: 2
) do
  Redis.new(url: redis_url)
end

idempo_backend = Idempo::RedisBackend.new(idempo_redis_pool)

Rails.application.config.middleware.insert_after Rack::Head, Idempo, backend: idempo_backend
