# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = Rails.env.production?

  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    payload = event.payload

    {
      request_id: payload[:request_id],
      remote_ip: payload[:remote_ip]
      # user_id: payload[:user_id],
      # merchant_id: payload[:merchant_id]
    }.compact
  end
end
