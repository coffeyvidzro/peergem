# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production staging]
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.send_default_pii = false
  config.traces_sample_rate = 0.001

  config.excluded_exceptions += [
    "ActionController::RoutingError",
    "ActionController::InvalidAuthenticityToken",
    "AbstractController::ActionNotFound",
    "ActionController::UnknownFormat",
    "ActionController::UnknownHttpMethod",
    "ActionController::BadRequest",
    "Mime::Type::InvalidMimeType",
    "ActionController::ParameterMissing"
  ]
end