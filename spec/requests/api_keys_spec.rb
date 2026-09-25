# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API keys" do
  let(:owner) { User.create!(email: "owner@example.com") }
  let(:merchant) do
    Merchants::Create.call(user: owner, attributes: { name: "Akwaaba", slug: "akwaaba", country_code: "GH" })
  end
  let(:session_token) { Session.issue(user: owner).last }
  let(:headers) { { "Authorization" => "Bearer #{session_token}" } }

  def create_api_key
    post "/merchants/#{merchant.public_id}/api_keys", params: {
      api_key: {
        name: "Backend",
        scopes: %w[payments:read payments:write],
        ip_allowlist: [ "127.0.0.0/8" ]
      }
    }, headers: headers
  end

  it "shows a new secret once and authenticates it independently from user sessions" do
    create_api_key
    secret = response.parsed_body.dig("api_key", "secret")

    expect(response).to have_http_status(:created)
    expect(secret).to match(ApiKey::TOKEN_PATTERN)

    expect(ApiKey.authenticate(secret, ip_address: "127.0.0.1").merchant).to eq(merchant)
  end

  it "never returns stored secrets when api_keys are listed" do
    create_api_key

    get "/merchants/#{merchant.public_id}/api_keys", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("api_keys", 0)).not_to have_key("secret")
  end

  it "atomically revokes the old api_key when rotating" do
    create_api_key
    original_secret = response.parsed_body.dig("api_key", "secret")
    api_key_id = response.parsed_body.dig("api_key", "id")

    post "/merchants/#{merchant.public_id}/api_keys/#{api_key_id}/rotate", headers: headers
    replacement_secret = response.parsed_body.dig("api_key", "secret")

    expect(response).to have_http_status(:created)
    expect(ApiKey.authenticate(original_secret, ip_address: "127.0.0.1")).to be_nil
    expect(ApiKey.authenticate(replacement_secret, ip_address: "127.0.0.1")).to be_present
  end

  it "renames a key without returning or replacing its secret" do
    create_api_key
    api_key_id = response.parsed_body.dig("api_key", "id")

    patch "/merchants/#{merchant.public_id}/api_keys/#{api_key_id}",
      params: { api_key: { name: "Checkout backend" } }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("api_key")).to include("name" => "Checkout backend")
    expect(response.parsed_body.fetch("api_key")).not_to have_key("secret")
  end

  it "does not allow an ordinary merchant member to manage api_keys" do
    member = User.create!(email: "member@example.com")
    merchant.merchant_memberships.create!(user: member, role: "member", joined_at: Time.current)
    member_token = Session.issue(user: member).last

    get "/merchants/#{merchant.public_id}/api_keys",
      headers: { "Authorization" => "Bearer #{member_token}" }

    expect(response).to have_http_status(:forbidden)
  end
end
