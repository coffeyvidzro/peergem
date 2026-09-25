# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Deactivate do
  it "disables a user and revokes all active sessions without deleting the identity" do
    user = User.create!(email: "member@example.com")
    session = Session.issue(user: user).first

    described_class.call(user: user, confirmation: "DEACTIVATE")

    expect(user.reload).to be_disabled
    expect(session.reload).to be_revoked
    expect(User.exists?(user.id)).to be(true)
  end

  it "requires a sole merchant owner to transfer ownership first" do
    user = User.create!(email: "owner@example.com")
    merchant = Merchants::Create.call(
      user: user,
      attributes: { name: "Akwaaba", slug: "akwaaba", country_code: "GH" }
    )

    expect { described_class.call(user: user, confirmation: "DEACTIVATE") }
      .to raise_error(Users::Deactivate::MerchantOwnershipRequiredError)
    expect(user.reload).not_to be_disabled
    expect(merchant.merchant_memberships.active.where(role: "owner")).to exist
  end

  it "requires explicit confirmation and reauthentication for a password identity" do
    user = User.create!(email: "member@example.com", password: "very-secure-password")

    expect { described_class.call(user: user, confirmation: nil) }
      .to raise_error(Users::Deactivate::ConfirmationRequiredError)
    expect { described_class.call(user: user, confirmation: "DEACTIVATE", password: "wrong") }
      .to raise_error(Users::Deactivate::ReauthenticationRequiredError)
    expect(user.reload).not_to be_disabled
  end
end
