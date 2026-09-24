# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User profile" do
  let!(:user) do
    User.create!(
      email: "user@example.com",
      confirmed_at: Time.current,
      name: "Ama Mensah",
      password: "a-secure-password",
      password_confirmation: "a-secure-password"
    )
  end
  let!(:other_session) { Session.issue(user: user).first }
  let(:token) { Session.issue(user: user).last }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /user" do
    it "returns the authenticated identity using its typed public ID" do
      get "/user", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("user")).to include(
        "id" => "usr_#{user.id}",
        "email" => "user@example.com",
        "email_verified" => true,
        "has_password" => true,
        "name" => "Ama Mensah"
      )
    end
  end

  describe "PATCH /user" do
    it "updates only the display name" do
      patch "/user", params: { name: "Akosua Mensah", email: "changed@example.com" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("user", "name")).to eq("Akosua Mensah")
      expect(user.reload.email).to eq("user@example.com")
    end
  end

  describe "DELETE /user" do
    it "deactivates the identity and revokes all of its sessions without deleting it" do
      delete "/user", params: { confirmation: "DEACTIVATE", password: "a-secure-password" }, headers: headers

      expect(response).to have_http_status(:no_content)
      expect(user.reload).to be_disabled
      expect(other_session.reload).to be_revoked
      expect(user.sessions.active).to be_empty
      expect(User.exists?(user.id)).to be(true)
    end
  end

  it "requires a bearer credential" do
    get "/user"

    expect(response).to have_http_status(:unauthorized)
  end
end
