# frozen_string_literal: true

require "yaml"

# Use the same reachable Redis endpoint for Rails job producers and workers.
redis_config = {
  url: Rails.application.config.x.redis_url
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)

  schedule = YAML.safe_load_file(Rails.root.join("config/sidekiq_schedule.yml"), aliases: true)
  Sidekiq::Cron::Job.load_from_hash!(schedule)
end

Sidekiq.configure_client do |config|
  config.redis = redis_config

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end

# Sidekiq uniqueness is not financial idempotency. Enforce payment and wallet
# deduplication with PostgreSQL constraints and transactional application logic.
Sidekiq.default_job_options = { "backtrace" => 10, "retry" => 10 }