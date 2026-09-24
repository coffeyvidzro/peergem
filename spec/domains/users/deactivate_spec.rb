# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Deactivate do
  it "disables a user and revokes all active sessions without deleting the identity" do
    user = User.create!(email: "member@example.com")
    session = Session.issue(user: user).first

    described_class.call(user: user)

    expect(user.reload).to be_disabled
    expect(session.reload).to be_revoked
    expect(User.exists?(user.id)).to be(true)
  end
end
