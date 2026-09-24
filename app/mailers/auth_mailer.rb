# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def email_code
    assign_code
    mail(to: params.fetch(:identifier), subject: "Your PeerGem verification code")
  end

  def password_reset_code
    assign_code
    mail(to: params.fetch(:identifier), subject: "Reset your PeerGem password")
  end

  private

  def assign_code
    @code = params.fetch(:code)
    @expires_in_minutes = params.fetch(:expires_in_minutes, 5)
  end
end