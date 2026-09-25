# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiCredential do
  let(:user) { User.create!(email: "owner@example.com") }
  let(:merchant) do
    Merchants::Create.call(user: user, attributes: { name: "Akwaaba", slug: "akwaaba", country_code: "GH" })
  end

  it "authenticates the issued secret without persisting it" do
    result = ApiCredentials::Issue.call(
      merchant: merchant,
      created_by: user,
      attributes: { name: "Server", scopes: [ "payments:read" ] }
    )

    expect(described_class.authenticate(result.secret, ip_address: "192.0.2.1")).to eq(result.credential)
    expect(result.credential.secret_digest).not_to include(result.secret)
    expect(result.credential.reload.last_used_ip.to_s).to eq("192.0.2.1")
  end

  it "enforces CIDR allowlists" do
    result = ApiCredentials::Issue.call(
      merchant: merchant,
      created_by: user,
      attributes: {
        name: "Restricted",
        scopes: [ "payments:write" ],
        ip_allowlist: [ "203.0.113.0/24" ]
      }
    )

    expect(described_class.authenticate(result.secret, ip_address: "192.0.2.1")).to be_nil
    expect(SecurityEvent.exists?(event_type: "api_credential.ip_rejected", merchant: merchant)).to be(true)
  end

  it "rejects unsupported scopes and invalid allowlist entries" do
    credential = described_class.new(scopes: [ "root" ], ip_allowlist: [ "not-an-ip" ])

    expect(credential).not_to be_valid
    expect(credential.errors[:scopes]).to include("contain unsupported values: root")
    expect(credential.errors[:ip_allowlist]).to include("must contain valid IP addresses or CIDR ranges")
  end
end
