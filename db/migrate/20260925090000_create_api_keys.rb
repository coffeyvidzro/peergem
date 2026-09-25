# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :merchant, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :created_by, type: :uuid, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :replaced_by, type: :uuid, foreign_key: { to_table: :api_keys, on_delete: :nullify }
      t.string :name, null: false
      t.string :key_id, null: false
      t.string :secret_digest, null: false
      t.string :scopes, array: true, null: false, default: []
      t.jsonb :ip_allowlist, null: false, default: []
      t.inet :last_used_ip
      t.timestamptz :last_used_at
      t.timestamptz :expires_at
      t.timestamptz :revoked_at
      t.timestamps
    end

    add_index :api_keys, :key_id, unique: true
    add_index :api_keys, [ :merchant_id, :created_at ]
    add_index :api_keys, :expires_at, where: "revoked_at IS NULL"
    add_check_constraint :api_keys, "jsonb_typeof(ip_allowlist) = 'array'", name: "chk_api_keys_ip_allowlist"
    add_check_constraint :api_keys, "expires_at IS NULL OR expires_at > created_at",
      name: "chk_api_keys_expiry"
    add_check_constraint :api_keys, "revoked_at IS NULL OR revoked_at >= created_at",
      name: "chk_api_keys_revoked"
  end
end
