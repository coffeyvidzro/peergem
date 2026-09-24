# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions" do
  let!(:user) { User.create!(email: "member@example.com", confirmed_at: Time.current) }
  let!(:current_session) { Session.issue(user: user, user_agent: "current").first }
  let(:token) { Session.issue(user: user, user_agent: "browser").last }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /sessions" do
    it "lists only the current user's active sessions" do
      other_user = User.create!(email: "other@example.com")
      Session.issue(user: other_user)
      current_session.revoke!

      get "/sessions", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("sessions").pluck("user_agent")).to eq([ "browser" ])
    end
  end

  describe "GET /sessions/:id" do
    it "returns a historical session owned by the current user" do
      current_session.revoke!

      get "/sessions/#{current_session.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("session", "id")).to eq(current_session.id)
      expect(response.parsed_body.dig("session", "revoked_at")).to be_present
    end

    it "does not expose another user's session" do
      other_user = User.create!(email: "other@example.com")
      other_session = Session.issue(user: other_user).first

      get "/sessions/#{other_session.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /sessions/:id" do
    it "revokes an owned session" do
      delete "/sessions/#{current_session.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(current_session.reload).to be_revoked
    end
  end

  describe "DELETE /sessions" do
    it "revokes all active sessions including the credential used for the request" do
      delete "/sessions", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(user.sessions.active).to be_empty
    end
  end

  it "requires a prefixed bearer credential" do
    get "/sessions", headers: { "Authorization" => "Bearer invalid" }

    expect(response).to have_http_status(:unauthorized)
  end
end
