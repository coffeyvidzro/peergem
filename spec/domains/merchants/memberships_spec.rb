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

    result = Merchants::Memberships::Update.call(
      merchant: merchant, membership: membership, actor: owner, attributes: { role: "admin" }
    )

    expect(result.reload.role).to eq("admin")
    expect(SecurityEvent.where(event_type: "merchant.membership_updated", merchant: merchant)).to exist
  end

  it "protects the last active owner on both updates and removal" do
    membership = merchant.merchant_memberships.find_by!(user: owner)

    expect {
      Merchants::Memberships::Update.call(
        merchant: merchant, membership: membership, actor: owner, attributes: { role: "admin" }
      )
    }.to raise_error(Pundit::NotAuthorizedError)
    expect {
      Merchants::Memberships::Remove.call(merchant: merchant, membership: membership, actor: owner)
    }.to raise_error(Pundit::NotAuthorizedError)

    expect(membership.reload.role).to eq("owner")
    expect(membership.reload.status).to eq("active")
  end

  it "allows a member to leave but prevents leaving on another user's behalf" do
    member = User.create!(email: "member-leave@example.com")
    membership = merchant.merchant_memberships.create!(user: member, role: "member")

    expect {
      Merchants::Memberships::Remove.call(
        merchant: merchant, membership: membership, actor: owner, leaving: true
      )
    }.to raise_error(Pundit::NotAuthorizedError)

    Merchants::Memberships::Remove.call(
      merchant: merchant, membership: membership, actor: member, leaving: true
    )

    expect(MerchantMembership.exists?(membership.id)).to be(false)
    expect(SecurityEvent.where(event_type: "merchant.membership_left", merchant: merchant)).to exist
  end
end
