# frozen_string_literal: true

require "yaml"

# Use the same reachable Redis endpoint for Rails job producers and workers.
redis_config = {
  url: Rails.application.config.x.redis_url
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  schedule = YAML.safe_load_file(Rails.root.join("config/sidekiq_schedule.yml"), aliases: true)
  Sidekiq::Cron::Job.load_from_hash!(schedule)
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Sidekiq uniqueness is not financial idempotency. Enforce payment and wallet
# deduplication with PostgreSQL constraints and transactional application logic.
Sidekiq.default_job_options = { "backtrace" => 10, "retry" => 5 }
