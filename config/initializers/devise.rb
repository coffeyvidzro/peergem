# frozen_string_literal: true

Devise.setup do |config|
  require "devise/orm/active_record"

  config.parent_controller = "ApplicationController"
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "no-reply@peergem.com")

  config.navigational_formats = ['*/*', :html, :turbo_stream]

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  config.paranoid = true
  config.reconfirmable = true
  config.reset_password_within = 1.hour

  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 12..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :time
  config.maximum_attempts = 7
  config.unlock_in = 1.hour
  config.last_attempt_warning = true

  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other

end