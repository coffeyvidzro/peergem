# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSerializer do
  it "preserves the public user representation" do
    user = User.create!(email: "member@example.com", confirmed_at: Time.current)

    expect(described_class.new(user).as_json).to include(
      id: user.public_id,
      email: user.email,
      email_verified: true,
      has_password: false,
      name: nil,
      created_at: user.created_at.iso8601
    )
  end
end
