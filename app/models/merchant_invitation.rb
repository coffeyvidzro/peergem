# frozen_string_literal: true

class MerchantInvitation < ApplicationRecord
  TOKEN_PREFIX = "pgi_"
  PUBLIC_ID_PREFIX = "inv_"
  UUID_PATTERN = Merchant::UUID_PATTERN
  DEFAULT_TTL = 7.days

  belongs_to :merchant
  belongs_to :invited_by, class_name: "User"

  validates :email, :token_digest, :expires_at, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, disposable_email: true
  validates :role, inclusion: { in: %w[admin member] }
  validates :email, uniqueness: {
    scope: :merchant_id,
    conditions: -> { where(accepted_at: nil, revoked_at: nil) }
  }

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :active, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  def active? = accepted_at.nil? && revoked_at.nil? && expires_at.future?
  def public_id = "#{PUBLIC_ID_PREFIX}#{id}"

  def self.id_from_public_id!(public_id)
    value = public_id.to_s
    raise ActiveRecord::RecordNotFound unless value.start_with?(PUBLIC_ID_PREFIX)

    id = value.delete_prefix(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless id.match?(UUID_PATTERN)

    id
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.find_by_token!(token)
    raise ActiveRecord::RecordNotFound unless token.to_s.start_with?(TOKEN_PREFIX)

    active.find_by!(token_digest: digest(token))
  end
end
