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

  describe "typed public IDs" do
    it "round-trips through the ses_ representation" do
      user = User.create!(email: "member@example.com")
      session = described_class.issue(user: user).first

      expect(session.public_id).to eq("ses_#{session.id}")
      expect(described_class.find_by_public_id!(session.public_id)).to eq(session)
    end

    it "rejects untyped IDs" do
      expect { described_class.find_by_public_id!(SecureRandom.uuid) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
