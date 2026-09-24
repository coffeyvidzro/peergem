# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Challenges::Verify do
  let(:transaction) { AuthTransaction.create!(identifier: "member@example.com") }

  it "consumes an OTP and authenticates the corresponding user" do
    code = "123456"
    transaction.send_otp!
    challenge = transaction.auth_challenges.create!(
      identifier: transaction.identifier,
      purpose: "email_otp",
      secret_hash: AuthChallenge.digest(code),
      expires_at: 10.minutes.from_now
    )

    user = described_class.call(transaction: transaction, code: code)

    expect(user.reload).to be_confirmed
    expect(challenge.reload).to be_consumed
    expect(transaction.reload).to be_authenticated
    expect(described_class.call(transaction: transaction, code: code)).to be_nil
  end

  it "records a failed verification attempt without consuming the challenge" do
    transaction.send_otp!
    challenge = transaction.auth_challenges.create!(
      identifier: transaction.identifier,
      purpose: "email_otp",
      secret_hash: AuthChallenge.digest("123456"),
      expires_at: 10.minutes.from_now
    )

    expect(described_class.call(transaction: transaction, code: "000000")).to be_nil
    expect(challenge.reload.attempts).to eq(1)
    expect(challenge).not_to be_consumed
  end
end
