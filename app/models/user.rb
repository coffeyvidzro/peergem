# frozen_string_literal: true

class User < ApplicationRecord
  PUBLIC_ID_PREFIX = "usr_"

  has_secure_password validations: false

  has_many :sessions,          dependent: :destroy
  has_many :auth_transactions, dependent: :destroy
  has_many :security_events, dependent: :nullify

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :name, length: { maximum: 120 }, allow_nil: true

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12, maximum: 72 }, allow_nil: true

  scope :active, -> { where(disabled_at: nil) }

  def confirmed? = confirmed_at.present?
  def disabled?  = disabled_at.present?
  def public_id  = "#{PUBLIC_ID_PREFIX}#{id}"

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def disable!
    update!(disabled_at: Time.current)
  end

    def active_for_authentication?
    super && disabled_at.nil? && email_verified?
  end

  def inactive_message
    disabled_at? ? :disabled : super
  end

  def email_verified?
    confirmed_at.present?
  end
end
