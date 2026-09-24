# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityEvent do
  it "records session issuance without storing the bearer token" do
    user = User.create!(email: "member@example.com")

    session, token = Session.issue(user: user, assurance: "otp", ip_address: "192.0.2.1")
    event = described_class.find_by!(event_type: "session.created")

    expect(event.user).to eq(user)
    expect(event.metadata).to include("session_id" => session.public_id, "assurance" => "otp")
    expect(event.metadata.to_json).not_to include(token)
  end

  it "does not permit application code to rewrite an audit event" do
    event = described_class.create!(event_type: "authentication.failed", occurred_at: Time.current)

    expect { event.update!(event_type: "authentication.succeeded") }
      .to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
