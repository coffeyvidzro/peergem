# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :sessions,          dependent: :destroy
  has_many :auth_transactions, dependent: :destroy
  
  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :name, length: { maximum: 120 }, allow_nil: true

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(disabled_at: nil) }

  def confirmed? = confirmed_at.present?
  def disabled?  = disabled_at.present?

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def disable!
    update!(disabled_at: Time.current)
  end
end