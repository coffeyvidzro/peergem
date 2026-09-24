# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication" do
  describe "POST /auth/start" do
    it "creates an unversioned authentication transaction without revealing account existence" do
      User.create!(email: "member@example.com", password: "very-secure-password")

      post "/auth/start", params: { email: "missing@example.com" }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "transaction_id" => be_present,
        "methods" => %w[email_otp password]
      )
    end
  end

  describe "POST /auth/password/login" do
    it "issues an opaque bearer session for valid credentials" do
      user = User.create!(email: "member@example.com", password: "very-secure-password")

      post "/auth/password/login", params: {
        transaction_id: AuthTransaction.create!(identifier: user.email, user: user).id,
        password: "very-secure-password"
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "token" => start_with("pgs_"),
        "token_type" => "Bearer",
        "user" => include("id" => user.public_id)
      )
      expect(SecurityEvent.exists?(event_type: "session.created", user: user)).to be(true)
    end
  end
end
