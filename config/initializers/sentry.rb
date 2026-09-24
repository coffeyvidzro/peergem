# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]

  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Act 843: never send PII to a third-party service.
  config.send_default_pii = false

  config.before_send = lambda do |event, _hint|
    Sentry::PiiScrubber.scrub(event.extra)    if event.extra
    Sentry::PiiScrubber.scrub(event.user)     if event.user
    Sentry::PiiScrubber.scrub(event.contexts) if event.contexts
    event
  end

  config.before_breadcrumb = lambda do |breadcrumb, _hint|
    Sentry::PiiScrubber.scrub(breadcrumb.data) if breadcrumb.data
    breadcrumb
  end

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