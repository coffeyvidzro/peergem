# frozen_string_literal: true

require "rails_helper"

RSpec.describe Merchants::Memberships::Remove do
  let(:owner) { User.create!(email: "owner-remove@example.com") }
  let(:merchant) do
    Merchants::Create.call(
      user: owner, attributes: { name: "Removal Store", slug: "removal-store", country_code: "GH" }
    )
  end

  it "protects the last active owner against removal" do
    membership = merchant.merchant_memberships.find_by!(user: owner)

    expect {
      described_class.call(merchant: merchant, membership: membership, actor: owner)
    }.to raise_error(Pundit::NotAuthorizedError)

    expect(membership.reload.status).to eq("active")
  end

  it "allows a member to leave but prevents leaving on another user's behalf" do
    member = User.create!(email: "member-leave@example.com")
    membership = merchant.merchant_memberships.create!(user: member, role: "member")

    expect {
      described_class.call(merchant: merchant, membership: membership, actor: owner, leaving: true)
    }.to raise_error(Pundit::NotAuthorizedError)

    described_class.call(merchant: merchant, membership: membership, actor: member, leaving: true)

    expect(MerchantMembership.exists?(membership.id)).to be(false)
    expect(SecurityEvent.where(event_type: "merchant.membership_left", merchant: merchant)).to exist
  end
end
