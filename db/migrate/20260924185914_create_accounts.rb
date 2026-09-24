# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.string :currency, null: false, limit: 3, default: "GHS"
      t.integer :platform_fee_percent,               null: true
      t.integer :platform_fee_fixed,                 null: true
      t.integer :platform_subscription_fee_percent,  null: true
      t.interval :payout_delay, null: false, default: "7 days"
      t.string :billing_name,             null: true
      t.jsonb  :billing_address,          null: true, default: {}
      t.bigint :credit_balance, null: false, default: 0
      t.timestamps
    end

    add_index :accounts, :billing_address, using: :gin
  end
end