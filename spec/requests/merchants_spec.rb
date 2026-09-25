# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Merchants and memberships" do
  let(:owner) { User.create!(email: "owner@example.com", confirmed_at: Time.current) }
  let(:owner_token) { Session.issue(user: owner).last }
  let(:owner_headers) { { "Authorization" => "Bearer #{owner_token}" } }

  def create_merchant
    post "/merchants", params: {
      merchant: { name: "Akwaaba Store", slug: "akwaaba-store", country_code: "gh" }
    }, headers: owner_headers
    Merchant.find_by_public_id!(response.parsed_body.dig("merchant", "id"))
  end

  it "creates a merchant and atomically assigns the creator as owner" do
    merchant = create_merchant

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.fetch("merchant")).to include(
      "id" => merchant.public_id,
      "country_code" => "GH",
      "role" => "owner"
    )
    expect(merchant.merchant_memberships.find_by(user: owner)).to have_attributes(role: "owner", status: "active")
  end

  it "lists only merchants belonging to the authenticated user" do
    merchant = create_merchant
    Merchant.create!(name: "Other", slug: "other", country_code: "GH")

    get "/merchants", headers: owner_headers

    expect(response.parsed_body.fetch("merchants").pluck("id")).to eq([ merchant.public_id ])
  end

  it "does not allow ordinary members to update a merchant" do
    merchant = create_merchant
    member = User.create!(email: "member@example.com")
    merchant.merchant_memberships.create!(user: member, role: "member", joined_at: Time.current)
    token = Session.issue(user: member).last

    patch "/merchants/#{merchant.public_id}", params: { merchant: { name: "Changed" } },
      headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:forbidden)
    expect(merchant.reload.name).to eq("Akwaaba Store")
  end

  it "issues a one-time invitation token and accepts it for the matching identity" do
    merchant = create_merchant
    invitee = User.create!(email: "invitee@example.com")
    invitee_token = Session.issue(user: invitee).last

    post "/merchants/#{merchant.public_id}/invitations", params: {
      invitation: { email: invitee.email, role: "member" }
    }, headers: owner_headers
    invitation_token = response.parsed_body.dig("invitation", "token")

    post "/merchant_invitations/accept", params: { token: invitation_token },
      headers: { "Authorization" => "Bearer #{invitee_token}" }

    expect(response).to have_http_status(:created)
    expect(merchant.merchant_memberships.find_by(user: invitee)).to have_attributes(role: "member")
    expect(MerchantInvitation.last.reload.accepted_at).to be_present
  end

  it "prevents removal of a merchant's final active owner" do
    merchant = create_merchant
    membership = merchant.merchant_memberships.find_by!(user: owner)

    delete "/merchants/#{merchant.public_id}/memberships/#{membership.public_id}", headers: owner_headers

    expect(response).to have_http_status(:forbidden)
    expect(MerchantMembership.exists?(membership.id)).to be(true)
  end

  it "rejects an invitation presented by a different email identity" do
    merchant = create_merchant
    result = MerchantInvitations::Issue.call(merchant: merchant, invited_by: owner,
      email: "invitee@example.com", role: "member")
    stranger = User.create!(email: "stranger@example.com")
    stranger_token = Session.issue(user: stranger).last

    post "/merchant_invitations/accept", params: { token: result.token },
      headers: { "Authorization" => "Bearer #{stranger_token}" }

    expect(response).to have_http_status(:forbidden)
    expect(merchant.merchant_memberships.exists?(user: stranger)).to be(false)
  end

  it "rejects invitations to disposable email providers" do
    merchant = create_merchant

    expect {
      post "/merchants/#{merchant.public_id}/invitations", params: {
        invitation: { email: "customer@0-mail.com", role: "member" }
      }, headers: owner_headers
    }.not_to change(MerchantInvitation, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "message")).to include("must not use a disposable email provider")
  end
end
