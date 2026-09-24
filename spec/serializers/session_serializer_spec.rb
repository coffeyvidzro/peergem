# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionSerializer do
  it "preserves the session summary and detail representations" do
    user = User.create!(email: "member@example.com")
    session = Session.issue(user: user, user_agent: "browser").first
    serializer = described_class.new(session, current_session: session)

    expect(serializer.as_json).to include(id: session.public_id, is_current: true, user_agent: "browser")
    expect(serializer.detailed_json(location: "Accra, Ghana")).to include(
      last_active_at: nil,
      location: "Accra, Ghana"
    )
  end
end
