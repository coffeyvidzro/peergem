# frozen_string_literal: true

require "rails_helper"

RSpec.describe DisposableEmailValidator do
  it "rejects a domain listed in the disposable email data file" do
    user = User.new(email: "customer@0-mail.com")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("must not use a disposable email provider")
  end

  it "rejects subdomains of a listed disposable provider case-insensitively" do
    user = User.new(email: "customer@Inbox.0-MAIL.COM")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("must not use a disposable email provider")
  end

  it "allows an email domain that is not listed" do
    user = User.new(email: "customer@example.com")

    expect(user).to be_valid
  end
end
