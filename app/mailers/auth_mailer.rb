# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def otp(email:, code:)
    @code = code
    mail(to: email, subject: "Your PeerGem sign-in code")
  end

  def password_reset(email:, code:)
    @code = code
    mail(to: email, subject: "Reset your PeerGem password")
  end
end
