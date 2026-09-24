# frozen_string_literal: true

Stoplight.configure do |config|
  config.data_store = if Rails.env.test?
    Stoplight::DataStore::Memory.new
  else
    redis = Redis.new(url: Rails.application.config.x.redis_url)
    Stoplight::DataStore::Redis.new(redis)
  end
  config.notifiers = [ Stoplight::Notifier::Logger.new(Rails.logger) ]
end
