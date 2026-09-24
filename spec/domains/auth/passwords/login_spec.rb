# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Passwords::Login do
  it "authenticates the user and completes the password transaction" do
    user = User.create!(email: "member@example.com", password: "very-secure-password")
    transaction = AuthTransaction.create!(identifier: user.email, user: user)

    expect(described_class.call(transaction: transaction, password: "very-secure-password")).to eq(user)
    expect(transaction.reload).to be_authenticated
  end

  it "rejects an incorrect password without completing authentication" do
    user = User.create!(email: "member@example.com", password: "very-secure-password")
    transaction = AuthTransaction.create!(identifier: user.email, user: user)

    expect(described_class.call(transaction: transaction, password: "incorrect")).to be(false)
    expect(transaction.reload).to be_started
  end
end
