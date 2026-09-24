# frozen_string_literal: true

class Merchant < ApplicationRecord
  has_many :merchant_memberships, dependent: :destroy
  has_many :users, through: :merchant_memberships
  has_many :merchant_invitations, dependent: :destroy
  has_many :security_events, dependent: :nullify
  has_one :account, dependent: :destroy

  validates :name, :slug, :country_code, :status, :account_type, :timezone, presence: true
end
