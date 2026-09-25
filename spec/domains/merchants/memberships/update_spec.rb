# frozen_string_literal: true

require "rails_helper"

RSpec.describe Merchants::Memberships::Update do
  let(:owner) { User.create!(email: "owner-memberships@example.com") }
  let(:merchant) do
    Merchants::Create.call(
      user: owner, attributes: { name: "Membership Store", slug: "membership-store", country_code: "GH" }
    )
  end

  it "updates a membership and records the existing audit event" do
    member = User.create!(email: "member-update@example.com")
    membership = merchant.merchant_memberships.create!(user: member, role: "member")

    result = described_class.call(
      merchant: merchant, membership: membership, actor: owner, attributes: { role: "admin" }
    )

    expect(result.reload.role).to eq("admin")
    expect(SecurityEvent.where(event_type: "merchant.membership_updated", merchant: merchant)).to exist
  end

  it "protects the last active owner against changing roles" do
    membership = merchant.merchant_memberships.find_by!(user: owner)

    expect {
      described_class.call(
        merchant: merchant, membership: membership, actor: owner, attributes: { role: "admin" }
      )
    }.to raise_error(Pundit::NotAuthorizedError)

    expect(membership.reload.role).to eq("owner")
    expect(membership.reload.status).to eq("active")
  end
end
