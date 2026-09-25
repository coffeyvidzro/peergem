# frozen_string_literal: true

module Merchants
  module Memberships
    class Update
      def self.call(merchant:, membership:, actor:, attributes:)
        merchant.with_lock do
          record = merchant.merchant_memberships.find(membership.id)
          changes = attributes.symbolize_keys.slice(:role, :status)
          PreserveOwner.call!(merchant: merchant, membership: record, changes: changes)

          record.assign_attributes(changes)
          record.save!
          Security::Events.record(
            "merchant.membership_updated",
            user: actor,
            merchant: merchant,
            metadata: { membership_id: record.public_id, role: record.role, status: record.status }
          )
          record
        end
      end
    end
  end
end
