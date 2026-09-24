# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = Rails.env.production?

  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.ignore_actions = [
    "OkComputer::OkComputerController#index",
    "OkComputer::OkComputerController#all"
  ]

  config.lograge.custom_options = lambda do |event|
    payload = event.payload

    {
      request_id: payload[:request_id]
    }.compact
  end
end