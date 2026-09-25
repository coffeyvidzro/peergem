# frozen_string_literal: true

module Merchants
  module Memberships
    class Remove
      def self.call(merchant:, membership:, actor:, leaving: false)
        merchant.with_lock do
          record = merchant.merchant_memberships.find(membership.id)
          raise Pundit::NotAuthorizedError if leaving && record.user_id != actor.id

          PreserveOwner.call!(merchant: merchant, membership: record)
          record.destroy!
          Security::Events.record(
            leaving ? "merchant.membership_left" : "merchant.membership_removed",
            user: actor,
            merchant: merchant,
            metadata: { membership_id: record.public_id }
          )
          record
        end
      end
    end
  end
end
