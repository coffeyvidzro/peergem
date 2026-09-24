


# frozen_string_literal: true

class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.citext :slug, null: false
      t.jsonb :slug_history, null: false, default: []
      t.citext :email
      t.string :website, limit: 2048
      t.jsonb :socials, null: false, default: []
      t.string :status, null: false, default: "onboarding"
      t.string :country_code, null: false
      t.string :account_type,  null: false, default: "express" # express, custom, standard
      t.string :timezone, null: false, default: "UTC"
      t.jsonb :metadata, null: false, default: {}
      t.timestamptz :created_at,        null: false, default: -> { "now()" }
      t.timestamptz :updated_at,        null: false, default: -> { "now()" }
    end

    add_check_constraint :merchants,
      "status IN ('onboarding', 'active', 'restricted', 'suspended', 'closed')",
      name: "chk_merchants_status"
    add_check_constraint :merchants, "jsonb_typeof(metadata) = 'object'", name: "chk_merchants_metadata"
    add_check_constraint :merchants, "jsonb_typeof(slug_history) = 'array'", name: "chk_merchants_slug_history"
    add_check_constraint :merchants, "jsonb_typeof(socials) = 'array'", name: "chk_merchants_socials"
    add_check_constraint :merchants, "char_length(country_code) = 2", name: "chk_merchants_country"
    add_index :merchants, [ :status, :created_at ]
    add_index :merchants, :slug, unique: true

    create_table :merchant_memberships, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :role, null: false, default: "member"
      t.string :status, null: false, default: "active"
      t.references :invited_by, type: :uuid, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamptz :joined_at
      t.timestamps
    end

    add_check_constraint :merchant_memberships,
      "role IN ('owner', 'admin', 'member')",
      name: "chk_merchant_memberships_role"
    add_check_constraint :merchant_memberships,
      "status IN ('active', 'suspended')",
      name: "chk_merchant_memberships_status"
    add_index :merchant_memberships, [ :merchant_id, :user_id ], unique: true
    add_index :merchant_memberships, [ :user_id, :status ]

    create_table :merchant_invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :invited_by, null: false, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.citext :email, null: false
      t.string :role, null: false, default: "member"
      t.string :token_digest, null: false
      t.timestamptz :expires_at, null: false
      t.timestamptz :accepted_at
      t.timestamptz :revoked_at
      t.timestamps
    end

    add_check_constraint :merchant_invitations,
      "role IN ('admin', 'member')",
      name: "chk_merchant_invitations_role"
    add_check_constraint :merchant_invitations,
      "expires_at > created_at",
      name: "chk_merchant_invitations_expiry"
    add_check_constraint :merchant_invitations,
      "accepted_at IS NULL OR accepted_at >= created_at",
      name: "chk_merchant_invitations_accepted"
    add_check_constraint :merchant_invitations,
      "revoked_at IS NULL OR revoked_at >= created_at",
      name: "chk_merchant_invitations_revoked"
    add_check_constraint :merchant_invitations,
      "accepted_at IS NULL OR revoked_at IS NULL",
      name: "chk_merchant_invitations_terminal_state"
    add_index :merchant_invitations, [ :merchant_id, :email ],
      unique: true,
      where: "accepted_at IS NULL AND revoked_at IS NULL",
      name: "idx_active_merchant_invites"
    add_index :merchant_invitations, :token_digest, unique: true

    add_reference :security_events, :merchant,
      type: :uuid,
      foreign_key: { on_delete: :nullify },
      index: false
    add_index :security_events, [ :merchant_id, :occurred_at ]
  end
end