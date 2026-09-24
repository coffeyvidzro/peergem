# frozen_string_literal: true

stoplight_redis_url = Rails.application.config.x.redis_url.sub(%r{/\d+\z}, "/3")

stoplight_pool = ConnectionPool.new(
  size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  timeout: 2
) do
  Redis.new(url: stoplight_redis_url)
end

Stoplight.configure do |config|
  config.data_store = if Rails.env.test?
    Stoplight::DataStore::Memory.new
  else
    Stoplight::DataStore::Redis.new(stoplight_pool)
  end

  config.notifiers = [ Stoplight::Notifier::Logger.new(Rails.logger) ]

  config.tracked_errors = [
    Faraday::Error,
    Stoplight::Error::RedLight
  ]

  config.skipped_errors = [
    ActiveRecord::RecordNotFound,
    ActiveRecord::RecordInvalid,
    Pundit::NotAuthorizedError,
    ActionController::ParameterMissing
  ]
end
