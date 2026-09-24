# frozen_string_literal: true

class AuthChallenge < ApplicationRecord
  PURPOSES = %w[email_otp password_reset magic_link].freeze

  belongs_to :auth_transaction, optional: true

  validates :identifier, :secret_hash, :expires_at, presence: true
  validates :purpose, inclusion: { in: PURPOSES }
  validates :attempts, numericality: { greater_than_or_equal_to: 0 }
  validates :max_attempts, numericality: { greater_than: 0 }
  validate :expiry_follows_creation
  validate :consumption_follows_creation

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  private

  def expiry_follows_creation
    return if expires_at.blank? || created_at.blank? || expires_at > created_at

    errors.add(:expires_at, "must be after creation")
  end

  def consumption_follows_creation
    return if consumed_at.blank? || created_at.blank? || consumed_at >= created_at

    errors.add(:consumed_at, "must not be before creation")
  end
end