# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API credentials" do
  let(:owner) { User.create!(email: "owner@example.com") }
  let(:merchant) do
    Merchants::Create.call(user: owner, attributes: { name: "Akwaaba", slug: "akwaaba", country_code: "GH" })
  end
  let(:session_token) { Session.issue(user: owner).last }
  let(:headers) { { "Authorization" => "Bearer #{session_token}" } }

  def create_credential
    post "/merchants/#{merchant.public_id}/api_credentials", params: {
      api_credential: {
        name: "Backend",
        scopes: %w[payments:read payments:write],
        ip_allowlist: [ "127.0.0.0/8" ]
      }
    }, headers: headers
  end

  it "shows a new secret once and authenticates it independently from user sessions" do
    create_credential
    secret = response.parsed_body.dig("api_credential", "secret")

    expect(response).to have_http_status(:created)
    expect(secret).to match(ApiCredential::TOKEN_PATTERN)

    get "/api_credentials/current", headers: { "Authorization" => "Bearer #{secret}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("merchant", "id")).to eq(merchant.public_id)
  end

  it "never returns stored secrets when credentials are listed" do
    create_credential

    get "/merchants/#{merchant.public_id}/api_credentials", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("api_credentials", 0)).not_to have_key("secret")
  end

  it "atomically revokes the old credential when rotating" do
    create_credential
    original_secret = response.parsed_body.dig("api_credential", "secret")
    credential_id = response.parsed_body.dig("api_credential", "id")

    post "/merchants/#{merchant.public_id}/api_credentials/#{credential_id}/rotate", headers: headers
    replacement_secret = response.parsed_body.dig("api_credential", "secret")

    expect(response).to have_http_status(:created)
    expect(ApiCredential.authenticate(original_secret, ip_address: "127.0.0.1")).to be_nil
    expect(ApiCredential.authenticate(replacement_secret, ip_address: "127.0.0.1")).to be_present
  end

  it "does not allow an ordinary merchant member to manage credentials" do
    member = User.create!(email: "member@example.com")
    merchant.merchant_memberships.create!(user: member, role: "member", joined_at: Time.current)
    member_token = Session.issue(user: member).last

    get "/merchants/#{merchant.public_id}/api_credentials",
      headers: { "Authorization" => "Bearer #{member_token}" }

    expect(response).to have_http_status(:forbidden)
  end
end
