# frozen_string_literal: true

class MerchantPolicy
  def initialize(user, merchant)
    @membership = merchant.merchant_memberships.active.find_by(user: user)
  end

  def show? = @membership.present?
  def update? = @membership&.role.in?(%w[owner admin])
  def manage_members? = update?
  def manage_owners? = @membership&.role == "owner"
  def manage_api_credentials? = @membership&.role.in?(%w[owner admin])
  def membership = @membership
end
