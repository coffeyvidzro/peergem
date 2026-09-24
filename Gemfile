source "https://rubygems.org"

# --- Framework ---
gem "rails", "8.1.3.1"
gem "propshaft", "~> 1.3.2"
gem "puma", "~> 8.0.2"
gem "rack-cors", "~> 3.0.0"
gem "fiddle", "~> 1.1.8"

# --- Frontend (ERB + Hotwire + Tailwind + importmap) ---
gem "importmap-rails", "~> 2.2.3"
gem "turbo-rails", "~> 2.0.23"
gem "stimulus-rails", "~> 1.3.4"
gem "tailwindcss-rails", "~> 4.6.0"
gem "jbuilder", "~> 2.15.1"
gem "image_processing", "~> 2.1.0"

# --- Cache, queues, locks (Redis-backed) ---
gem "redis", "~> 6.0.0"
gem "sidekiq", "~> 8.1.7"
gem "sidekiq-cron", "~> 2.4.0"
gem "redlock", "~> 2.1.0"
gem "idempo", "~> 1.4.0"

# --- Domain: state machines & money ---
gem "aasm", "~> 6.0.0"
gem "countries", "~> 8.1.0"
gem "money", "~> 7.1.1"
gem "pagy", "~> 43.6.3"
gem "avatax", "~> 26.9.0"

# --- Outbound HTTP ---
gem "faraday", "~> 2.14.4"
gem "faraday-retry", "~> 2.4.0"
gem "lockbox", "~> 2.2.0"
gem "stoplight", "~> 5.8.3"

# --- External services ---
gem "maxmind-geoip2", "~> 1.6.0"
gem "aws-sdk-s3", "~> 1.232.1", require: false
gem "aws-sdk-sesv2", "~> 1.110.0", require: false

# --- Observability & health ---
gem "lograge", "~> 0.15.0"
gem "okcomputer", "~> 1.20.0"
gem "sentry-ruby", "~> 7.0.0"
gem "sentry-rails", "~> 7.0.0"
gem "sentry-sidekiq", "~> 7.0.0"

# --- Auth ---
gem "bcrypt", "~> 3.1.22"
gem "devise", "~> 5.0.4"
gem "pundit", "~> 2.5.2"
gem "rack-attack", "~> 6.8.0"

# --- Platform ---
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", "~> 1.26.0", require: false
gem "ruby-vips", "~> 2.3.0", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", "~> 0.9.3", require: false
  gem "brakeman", "~> 8.0.6", require: false

  gem "rspec-rails", "~> 8.0.4"
  gem "rubocop-rails", "~> 2.38.0", require: false
  gem "rubocop-rspec", "~> 3.10.2", require: false
  gem "rubocop-performance", "~> 1.27.0", require: false
  gem "rubocop-rails-omakase", "~> 1.1.0", require: false
end

group :test do
  gem "factory_bot_rails", "~> 6.5.1"
  gem "shoulda-matchers", "~> 8.0.1"
end