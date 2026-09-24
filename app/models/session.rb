# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  ASSURANCES = %w[unknown password otp mfa].freeze

  validates :token_hash, presence: true, uniqueness: true
  validates :assurance,  inclusion: { in: ASSURANCES }

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  # Issues a new session. Returns [session, plaintext_token].
  # Only the SHA-256 hash of the token is persisted.
  def self.issue(user:, assurance: "password", ttl: 30.days, ip_address: nil, user_agent: nil)
    plaintext = SecureRandom.urlsafe_base64(32)
    session = create!(
      user:        user,
      token_hash:  Digest::SHA256.hexdigest(plaintext),
      assurance:   assurance,
      expires_at:  ttl.from_now,
      ip_address:  ip_address,
      user_agent:  user_agent
    )
    [session, plaintext]
  end

  def self.find_by_token(plaintext)
    active.find_by(token_hash: Digest::SHA256.hexdigest(plaintext))
  end

  def revoked? = revoked_at.present?
  def expired? = expires_at <= Time.current
  def active?  = !revoked? && !expired?

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_seen!
    update_column(:last_seen_at, Time.current)
  end
end