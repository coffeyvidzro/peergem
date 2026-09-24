# frozen_string_literal: true

require "rails_helper"

RSpec.describe Session do
  describe ".issue" do
    it "returns an opaque prefixed token and persists only its digest" do
      user = User.create!(email: "member@example.com")

      session, token = described_class.issue(user: user)

      expect(token).to start_with("pgs_")
      expect(session.token_hash).to eq(Digest::SHA256.hexdigest(token))
      expect(session.token_hash).not_to include(token)
      expect(described_class.find_by_token(token)).to eq(session)
    end
  end
end
