# frozen_string_literal: true

OkComputer.mount_at = false

class RedisHealthCheck < OkComputer::Check
  def check
    redis = Redis.new(url: Rails.application.config.x.redis_url, connect_timeout: 1, read_timeout: 1, write_timeout: 1)
    if redis.ping == "PONG"
      mark_message "Redis reachable"
    else
      mark_failure
      mark_message "Redis unavailable"
    end
  rescue Redis::BaseError, IOError, SystemCallError
    mark_failure
    mark_message "Redis unavailable"
  ensure
    redis&.close
  end
end

OkComputer::Registry.register "redis", RedisHealthCheck.new
OkComputer::Registry.register "database", OkComputer::ActiveRecordCheck.new

if Rails.env.production? || Rails.env.staging?
  OkComputer.require_authentication(
    ENV.fetch("HEALTHCHECK_USERNAME"),
    ENV.fetch("HEALTHCHECK_PASSWORD")
  )
end
