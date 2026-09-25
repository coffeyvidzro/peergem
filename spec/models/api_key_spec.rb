# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiKey do
  let(:user) { User.create!(email: "owner@example.com") }
  let(:merchant) do
    Merchants::Create.call(user: user, attributes: { name: "Akwaaba", slug: "akwaaba", country_code: "GH" })
  end

  it "authenticates the issued secret without persisting it" do
    result = Merchants::ApiKeys::Issue.call(
      merchant: merchant,
      created_by: user,
      attributes: { name: "Server", scopes: [ "payments:read" ] }
    )

    expect(described_class.authenticate(result.secret, ip_address: "192.0.2.1")).to eq(result.api_key)
    expect(result.api_key.secret_digest).not_to include(result.secret)
    expect(result.api_key.reload.last_used_ip.to_s).to eq("192.0.2.1")
  end

  it "enforces CIDR allowlists" do
    result = Merchants::ApiKeys::Issue.call(
      merchant: merchant,
      created_by: user,
      attributes: {
        name: "Restricted",
        scopes: [ "payments:write" ],
        ip_allowlist: [ "203.0.113.0/24" ]
      }
    )

    expect(described_class.authenticate(result.secret, ip_address: "192.0.2.1")).to be_nil
    expect(SecurityEvent.exists?(event_type: "api_key.ip_rejected", merchant: merchant)).to be(true)
  end

  it "rejects unsupported scopes and invalid allowlist entries" do
    api_key = described_class.new(scopes: [ "root" ], ip_allowlist: [ "not-an-ip" ])

    expect(api_key).not_to be_valid
    expect(api_key.errors[:scopes]).to include("contain unsupported values: root")
    expect(api_key.errors[:ip_allowlist]).to include("must contain valid IP addresses or CIDR ranges")
  end
end
