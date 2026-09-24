# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references  :user,           null: false, type: :uuid,
                                     foreign_key: { on_delete: :cascade }
      t.text        :token_hash,     null: false
      t.text        :assurance,      null: false, default: "unknown"
      t.inet        :ip_address
      t.text        :user_agent
      t.timestamptz :expires_at,     null: false
      t.timestamptz :last_seen_at
      t.timestamptz :revoked_at
      t.timestamptz :created_at,     null: false, default: -> { "now()" }
    end

    add_check_constraint :sessions,
      "expires_at > created_at",
      name: "chk_sessions_expiry"

    add_check_constraint :sessions,
      "revoked_at IS NULL OR revoked_at >= created_at",
      name: "chk_sessions_revoked"

    add_check_constraint :sessions,
      "assurance IN ('unknown', 'password', 'otp', 'mfa')",
      name: "chk_sessions_assurance"

    add_index :sessions, :token_hash,
              unique: true,
              name: "sessions_token_hash_idx"

    add_index :sessions, :user_id,
              name: "sessions_user_id_idx"

    add_index :sessions, :expires_at,
              name: "sessions_expires_at_idx"

    add_index :sessions, :user_id,
              where: "revoked_at IS NULL",
              name: "sessions_active_idx"
  end
end