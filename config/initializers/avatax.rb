# frozen_string_literal: true

endpoint = ENV.fetch(
  "AVATAX_ENDPOINT",
  Rails.env.production? ? "https://rest.avatax.com" : "https://sandbox-rest.avatax.com"
)
username = Rails.env.production? ? ENV.fetch("AVATAX_USERNAME") : ENV["AVATAX_USERNAME"]
password = Rails.env.production? ? ENV.fetch("AVATAX_PASSWORD") : ENV["AVATAX_PASSWORD"]

AvaTax.configure do |config|
  config.app_name = "PeerGem"
  config.app_version = ENV.fetch("APP_VERSION", "development")
  config.machine_name = ENV.fetch("HOSTNAME", "peergem")
  config.endpoint = endpoint
  config.username = username
  config.password = password

  config.response_big_decimal_conversion = true
  config.connection_options = {
    request: {
      open_timeout: 2,
      timeout: 5
    }
  }

  config.logger = false
  config.log_request_and_response_info = false
end

Rails.application.config.x[:avatax] ||= ActiveSupport::OrderedOptions.new
Rails.application.config.x.avatax.client = AvaTax::Client.new
