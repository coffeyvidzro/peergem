# frozen_string_literal: true

class AuthSession < ApplicationRecord
  self.table_name = "sessions"

  PUBLIC_ID_PREFIX = "ses_"
  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
  ASSURANCE_LEVELS = %w[unknown password otp mfa].freeze

  belongs_to :user, inverse_of: :sessions

  validates :token_hash, :expires_at, presence: true
  validates :token_hash, uniqueness: true
  validates :assurance, inclusion: { in: ASSURANCE_LEVELS }
  validate :expiry_follows_creation
  validate :revocation_follows_creation

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.id_from_public_id!(public_id)
    value = public_id.to_s
    id = value.delete_prefix(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless value.start_with?(PUBLIC_ID_PREFIX) && id.match?(UUID_PATTERN)

    id
  end

  def public_id
    "#{PUBLIC_ID_PREFIX}#{id}"
  end

  private

  def expiry_follows_creation
    return if expires_at.blank? || created_at.blank? || expires_at > created_at

    errors.add(:expires_at, "must be after creation")
  end

  def revocation_follows_creation
    return if revoked_at.blank? || created_at.blank? || revoked_at >= created_at

    errors.add(:revoked_at, "must not be before creation")
  end
end