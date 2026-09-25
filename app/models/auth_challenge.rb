# frozen_string_literal: true

class AuthChallenge < ApplicationRecord
  OTP_TTL = 10.minutes
  RESEND_COOLDOWN = 60.seconds

  belongs_to :auth_transaction

  PURPOSES = %w[email_otp email_verification password_reset magic_link].freeze

  validates :identifier,  presence: true
  validates :identifier,  disposable_email: true
  validates :secret_hash, presence: true
  validates :purpose,     inclusion: { in: PURPOSES }

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  def consumed?  = consumed_at.present?
  def expired?   = expires_at <= Time.current
  def exhausted? = attempts >= max_attempts

  def consume!
    update!(consumed_at: Time.current)
  end

  def increment_attempts!
    increment!(:attempts)
  end

  def verify(code)
    return false if consumed? || expired? || exhausted?

    increment_attempts!
    ActiveSupport::SecurityUtils.secure_compare(secret_hash, self.class.digest(code))
  end

  def resend_available_at
    created_at + RESEND_COOLDOWN
  end

  def self.digest(code)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code.to_s)
  end
end
