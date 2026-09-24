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

  it "performs a password hash check when the identity does not exist" do
    transaction = AuthTransaction.create!(identifier: "missing@example.com")
    password = instance_double(BCrypt::Password)
    allow(BCrypt::Password).to receive(:new).and_return(password)
    allow(password).to receive(:is_password?).with("incorrect").and_return(false)

    expect(described_class.call(transaction: transaction, password: "incorrect")).to be(false)
    expect(password).to have_received(:is_password?).with("incorrect")
  end
end
