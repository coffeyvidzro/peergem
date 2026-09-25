class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "PeerGem <no-reply@peergem.com>")
  layout "mailer"
end
