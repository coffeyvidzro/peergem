# frozen_string_literal: true

class MerchantMembership < ApplicationRecord
  PUBLIC_ID_PREFIX = "mem_"
  UUID_PATTERN = Merchant::UUID_PATTERN
  ROLES = %w[owner admin member].freeze
  STATUSES = %w[active suspended].freeze

  belongs_to :merchant
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :merchant_id }
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def public_id = "#{PUBLIC_ID_PREFIX}#{id}"

  def self.id_from_public_id!(public_id)
    value = public_id.to_s
    raise ActiveRecord::RecordNotFound unless value.start_with?(PUBLIC_ID_PREFIX)

    id = value.delete_prefix(PUBLIC_ID_PREFIX)
    raise ActiveRecord::RecordNotFound unless id.match?(UUID_PATTERN)

    id
  end
end
