class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "PeerGem <noreply@peergem.local>")
  layout "mailer"
end
