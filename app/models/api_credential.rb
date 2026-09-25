# frozen_string_literal: true

require "ipaddr"

class ApiCredential < ApplicationRecord
  PUBLIC_ID_PREFIX = "key_"
  TOKEN_PATTERN = /\Apgk_([0-9a-f]{24})_([A-Za-z0-9_-]{43})\z/
  SCOPES = %w[
    payments:read payments:write customers:read customers:write
    payouts:read payouts:write webhooks:read webhooks:write
  ].freeze

  belongs_to :merchant
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :replaced_by, class_name: "ApiCredential", optional: true

  validates :name, :key_id, :secret_digest, presence: true
  validates :key_id, uniqueness: true, format: { with: /\A[0-9a-f]{24}\z/ }
  validate :scopes_are_supported
  validate :ip_allowlist_is_valid
  validate :expiry_is_in_the_future, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def public_id = "#{PUBLIC_ID_PREFIX}#{id}"
  def active? = revoked_at.nil? && (expires_at.nil? || expires_at.future?)

  def self.id_from_public_id!(public_id)
    value = public_id.to_s
    raise ActiveRecord::RecordNotFound unless value.start_with?(PUBLIC_ID_PREFIX)

    id = value.delete_prefix(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless id.match?(Merchant::UUID_PATTERN)

    id
  end

  def allows_scope?(scope)
    scopes.include?(scope.to_s)
  end

  def allows_ip?(address)
    return true if ip_allowlist.empty?

    ip = IPAddr.new(address.to_s)
    ip_allowlist.any? { IPAddr.new(_1).include?(ip) }
  rescue IPAddr::InvalidAddressError
    false
  end

  def self.authenticate(token, ip_address:)
    match = TOKEN_PATTERN.match(token.to_s)
    return unless match

    key_id, secret = match.captures
    credential = active.includes(:merchant).find_by(key_id: key_id)
    return unless credential
    return unless credential.merchant.status.in?(%w[onboarding active])
    return unless ActiveSupport::SecurityUtils.secure_compare(credential.secret_digest, digest(secret))

    unless credential.allows_ip?(ip_address)
      Security::Events.record(
        "api_credential.ip_rejected",
        merchant: credential.merchant,
        ip_address: ip_address,
        metadata: { api_credential_id: credential.public_id }
      )
      return
    end

    credential.record_usage!(ip_address)
    credential
  end

  def self.digest(secret)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, secret)
  end

  def record_usage!(ip_address)
    return if last_used_at&.after?(5.minutes.ago) && last_used_ip&.to_s == ip_address.to_s

    update_columns(last_used_at: Time.current, last_used_ip: ip_address) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def scopes_are_supported
    invalid = scopes - SCOPES
    errors.add(:scopes, "contain unsupported values: #{invalid.join(', ')}") if invalid.any?
  end

  def ip_allowlist_is_valid
    errors.add(:ip_allowlist, "must be an array") and return unless ip_allowlist.is_a?(Array)

    ip_allowlist.each { IPAddr.new(_1) }
  rescue IPAddr::InvalidAddressError
    errors.add(:ip_allowlist, "must contain valid IP addresses or CIDR ranges")
  end

  def expiry_is_in_the_future
    errors.add(:expires_at, "must be in the future") if expires_at && !expires_at.future?
  end
end
