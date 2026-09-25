# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::Fees do
  let(:account) { Account.new }

  it "calculates checkout fees using integer pesewas and half-up rounding" do
    expect(described_class.checkout(account: account, amount_in_pesewas: 2_500)).to eq(175)
    expect(described_class.checkout(account: account, amount_in_pesewas: 10)).to eq(51)
    expect(account.calculate_fee_in_pesewas(2_500)).to eq(175)
  end

  it "uses merchant account fee overrides without changing the public model API" do
    account.platform_fee_percent = 250
    account.platform_fee_fixed = 25
    account.platform_subscription_fee_percent = 200

    expect(account.calculate_fee_in_pesewas(2_500)).to eq(88)
    expect(account.calculate_subscription_fee_in_pesewas(2_500)).to eq(50)
  end

  it "rounds recurring subscription fees to a whole pesewa" do
    expect(described_class.subscription(account: account, amount_in_pesewas: 2_500)).to eq(100)
    expect(described_class.subscription(account: account, amount_in_pesewas: 13)).to eq(1)
  end
end
