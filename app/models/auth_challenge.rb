# frozen_string_literal: true

class AuthChallenge < ApplicationRecord
  belongs_to :auth_transaction

  PURPOSES = %w[email_otp email_verification password_reset magic_link].freeze

  validates :identifier,  presence: true
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
end