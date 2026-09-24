# frozen_string_literal: true

class MerchantInvitation < ApplicationRecord
  belongs_to :merchant
  belongs_to :invited_by, class_name: "User"

  validates :email, :token_digest, :expires_at, presence: true
  validates :role, inclusion: { in: %w[admin member] }
end
