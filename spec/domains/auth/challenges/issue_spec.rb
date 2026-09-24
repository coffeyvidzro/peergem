# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Challenges::Issue do
  let(:transaction) { AuthTransaction.create!(identifier: "member@example.com") }

  it "issues an email OTP challenge and schedules the sign-in email" do
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
    expect(AuthMailer).to receive(:otp).with(email: transaction.identifier, code: /\A\d{6}\z/).and_return(delivery)

    challenge = described_class.call(transaction: transaction, purpose: "email_otp")

    expect(challenge).to be_persisted
    expect(challenge.purpose).to eq("email_otp")
    expect(challenge).not_to be_expired
  end

  it "issues a password reset challenge using the same shared workflow" do
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
    expect(AuthMailer).to receive(:password_reset).with(email: transaction.identifier, code: /\A\d{6}\z/).and_return(delivery)

    challenge = described_class.call(transaction: transaction, purpose: "password_reset")

    expect(challenge.purpose).to eq("password_reset")
    expect(challenge.secret_hash).to match(/\A[0-9a-f]{64}\z/)
  end
end
