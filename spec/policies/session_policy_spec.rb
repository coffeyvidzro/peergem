# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionPolicy do
  it "allows access to an owned session and denies another user's session" do
    user = User.create!(email: "member@example.com")
    other_user = User.create!(email: "other@example.com")

    expect(described_class.new(user, Session.issue(user: user).first).show?).to be(true)
    expect(described_class.new(user, Session.issue(user: other_user).first).show?).to be(false)
  end
end
