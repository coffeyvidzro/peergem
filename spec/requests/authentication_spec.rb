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

    it "rejects disposable email providers before creating an authentication transaction" do
      expect {
        post "/auth/start", params: { email: "customer@0-mail.com" }
      }.not_to change(AuthTransaction, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "message")).to include("must not use a disposable email provider")
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

  describe "POST /auth/password/change" do
    it "changes the password and revokes every other session" do
      user = User.create!(email: "member@example.com", password: "very-secure-password")
      current_session, token = Session.issue(user: user)
      other_session = Session.issue(user: user).first

      post "/auth/password/change", params: {
        current_password: "very-secure-password",
        password: "new-very-secure-password",
        password_confirmation: "new-very-secure-password"
      }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:no_content)
      expect(user.reload.authenticate("new-very-secure-password")).to eq(user)
      expect(current_session.reload).not_to be_revoked
      expect(other_session.reload).to be_revoked
    end
  end
end
