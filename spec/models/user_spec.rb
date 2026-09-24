# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "#public_id" do
    it "adds the user type prefix to the database UUID" do
      user = described_class.new(id: SecureRandom.uuid)

      expect(user.public_id).to eq("usr_#{user.id}")
    end
  end
end
