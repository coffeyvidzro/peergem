# frozen_string_literal: true

class Merchant < ApplicationRecord
  PUBLIC_ID_PREFIX = "mer_"
  UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i
  STATUSES = %w[onboarding active restricted suspended closed].freeze
  ACCOUNT_TYPES = %w[express custom standard].freeze

  has_many :merchant_memberships, dependent: :destroy
  has_many :users, through: :merchant_memberships
  has_many :merchant_invitations, dependent: :destroy
  has_many :security_events, dependent: :nullify
  has_one :account, dependent: :destroy

  validates :name, :slug, :country_code, :status, :account_type, :timezone, presence: true
  validates :slug, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :country_code, length: { is: 2 }
  validates :status, inclusion: { in: STATUSES }
  validates :account_type, inclusion: { in: ACCOUNT_TYPES }

  normalizes :slug, with: ->(slug) { slug.strip.downcase }
  normalizes :country_code, with: ->(code) { code.strip.upcase }

  def public_id = "#{PUBLIC_ID_PREFIX}#{id}"

  def self.find_by_public_id!(public_id)
    value = public_id.to_s
    raise ActiveRecord::RecordNotFound unless value.start_with?(PUBLIC_ID_PREFIX)

    id = value.delete_prefix(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless id.match?(UUID_PATTERN)

    find(id)
  rescue ActiveRecord::StatementInvalid, ArgumentError
    raise ActiveRecord::RecordNotFound
  end
end
