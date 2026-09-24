# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Start do
  it "does not reveal whether an email has a password" do
    User.create!(email: "member@example.com", password: "very-secure-password")

    _, existing_methods = described_class.call(email: "member@example.com")
    _, missing_methods = described_class.call(email: "missing@example.com")

    expect(existing_methods).to eq(%w[email_otp password])
    expect(missing_methods).to eq(existing_methods)
  end
end
