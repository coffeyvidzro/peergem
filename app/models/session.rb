# frozen_string_literal: true

class Session < ApplicationRecord
  PUBLIC_ID_PREFIX = "ses_"
  TOKEN_PREFIX = "pgs_"
  IDLE_TIMEOUT = 24.hours
  ACTIVITY_WRITE_INTERVAL = 5.minutes

  belongs_to :user

  ASSURANCES = %w[unknown password otp mfa].freeze

  validates :token_hash, presence: true, uniqueness: true
  validates :assurance,  inclusion: { in: ASSURANCES }

  scope :active, lambda {
    now = Time.current
    where(sessions: { revoked_at: nil })
      .where("sessions.expires_at > ?", now)
      .where("COALESCE(sessions.last_seen_at, sessions.created_at) > ?", now - IDLE_TIMEOUT)
  }

  # Issues a new session. Returns [session, plaintext_token].
  # Only the SHA-256 hash of the token is persisted.
  def self.issue(user:, assurance: "password", ttl: 30.days, ip_address: nil, user_agent: nil)
    plaintext = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    transaction do
      session = create!(
        user:        user,
        token_hash:  Digest::SHA256.hexdigest(plaintext),
        assurance:   assurance,
        expires_at:  ttl.from_now,
        ip_address:  ip_address,
        user_agent:  user_agent
      )
      Security::Events.record(
        "session.created",
        user: user,
        ip_address: ip_address,
        user_agent: user_agent,
        metadata: { session_id: session.public_id, assurance: assurance }
      )
      [ session, plaintext ]
    end
  end

  def self.find_by_token(plaintext)
    return unless plaintext&.start_with?(TOKEN_PREFIX)

    session = active.joins(:user).merge(User.active).find_by(token_hash: Digest::SHA256.hexdigest(plaintext))
    session&.touch_seen!
    session
  end

  def self.find_by_public_id!(public_id)
    id = public_id.to_s.delete_prefix(PUBLIC_ID_PREFIX) if public_id.to_s.start_with?(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless id&.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

    find(id)
  end

  def revoked? = revoked_at.present?
  def expired? = expires_at <= Time.current
  def idle? = (last_seen_at || created_at) <= IDLE_TIMEOUT.ago
  def active?  = !revoked? && !expired? && !idle?
  def public_id = "#{PUBLIC_ID_PREFIX}#{id}"

  def revoke!(ip_address: nil, user_agent: nil)
    transaction do
      update!(revoked_at: Time.current)
      Security::Events.record(
        "session.revoked",
        user: user,
        ip_address: ip_address,
        user_agent: user_agent,
        metadata: { session_id: public_id }
      )
    end
  end

  def touch_seen!
    return if last_seen_at&.after?(ACTIVITY_WRITE_INTERVAL.ago)

    update_column(:last_seen_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
