# frozen_string_literal: true

class AuthTransaction < ApplicationRecord
  include AASM

  belongs_to :user, optional: true
  has_many   :auth_challenges, dependent: :destroy

  STATES  = %w[started otp_sent otp_verified password_required authenticated expired].freeze
  METHODS = %w[otp password].freeze

  validates :identifier, presence: true
  validates :state,           inclusion: { in: STATES }
  validates :selected_method, inclusion: { in: METHODS }, allow_nil: true

  scope :active,  -> { where.not(state: %w[authenticated expired]).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  before_create :set_expiry

  aasm column: :state do
    state :started,           initial: true
    state :otp_sent
    state :otp_verified
    state :password_required
    state :authenticated
    state :expired

    event :send_otp do
      transitions from: :started, to: :otp_sent
    end

    event :verify_otp do
      transitions from: :otp_sent, to: :otp_verified
    end

    event :require_password do
      transitions from: :otp_verified, to: :password_required
    end

    event :authenticate do
      transitions from: [:otp_verified, :password_required], to: :authenticated
    end

    event :expire do
      transitions from: [:started, :otp_sent, :otp_verified, :password_required], to: :expired
    end
  end

  def expired? = expires_at <= Time.current

  private

  def set_expiry
    self.expires_at ||= 15.minutes.from_now
  end
end