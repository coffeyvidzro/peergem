# frozen_string_literal: true

class MerchantMembership < ApplicationRecord
  belongs_to :merchant
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  validates :role, inclusion: { in: %w[owner admin member] }
  validates :status, inclusion: { in: %w[active suspended] }
end
