# frozen_string_literal: true

module Merchants
  module Memberships
    class PreserveOwner
      def self.call!(merchant:, membership:, changes: nil)
        return unless membership.role == "owner" && membership.status == "active"

        remains_owner = changes &&
          changes.fetch(:role, membership.role) == "owner" &&
          changes.fetch(:status, membership.status) == "active"
        return if remains_owner
        return if merchant.merchant_memberships.active.where(role: "owner").where.not(id: membership.id).exists?

        raise Pundit::NotAuthorizedError, "A merchant must retain an active owner"
      end
    end
  end
end
