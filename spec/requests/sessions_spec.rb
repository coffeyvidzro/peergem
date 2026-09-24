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
      expect(response.parsed_body.fetch("sessions")).to contain_exactly(
        include("id" => start_with("ses_"), "is_current" => true, "user_agent" => "browser")
      )
    end
  end

  describe "GET /sessions/:id" do
    it "returns a historical session owned by the current user" do
      current_session.revoke!

      get "/sessions/#{current_session.public_id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("session", "id")).to eq(current_session.public_id)
    end

    it "does not expose another user's session" do
      other_user = User.create!(email: "other@example.com")
      other_session = Session.issue(user: other_user).first

      get "/sessions/#{other_session.public_id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /sessions/:id" do
    it "revokes an owned session" do
      delete "/sessions/#{current_session.public_id}", headers: headers

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

  it "returns a best-effort location for an individual session" do
    current_session.update!(ip_address: "192.0.2.1", last_seen_at: Time.current)
    city = instance_double(MaxMind::GeoIP2::Record::City, name: "Accra")
    country = instance_double(MaxMind::GeoIP2::Record::Country, name: "Ghana")
    result = instance_double(MaxMind::GeoIP2::Model::City, city: city, country: country)
    reader = instance_double(MaxMind::GeoIP2::Reader, city: result)
    allow(Rails.application.config.x.geoip).to receive(:reader).and_return(reader)

    get "/sessions/#{current_session.public_id}", headers: headers

    expect(response.parsed_body.fetch("session")).to include(
      "location" => "Accra, Ghana",
      "last_active_at" => be_present
    )
  end

  it "does not fail when the GeoIP lookup fails" do
    current_session.update!(ip_address: "192.0.2.1")
    reader = instance_double(MaxMind::GeoIP2::Reader)
    allow(reader).to receive(:city).and_raise(MaxMind::GeoIP2::AddressNotFoundError)
    allow(Rails.application.config.x.geoip).to receive(:reader).and_return(reader)

    get "/sessions/#{current_session.public_id}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("session", "location")).to be_nil
  end
end
