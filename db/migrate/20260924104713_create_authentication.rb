# frozen_string_literal: true

class CreateAuthentication < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_transactions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.citext      :identifier,      null: false
      t.references  :user,            type: :uuid, foreign_key: { on_delete: :cascade }
      t.text        :state,           null: false, default: "started"
      t.text        :selected_method
      t.timestamptz :expires_at,      null: false
      t.timestamptz :created_at,      null: false, default: -> { "now()" }
      t.timestamptz :updated_at,      null: false, default: -> { "now()" }
    end

    add_check_constraint :auth_transactions,
      "state IN ('started', 'otp_sent', 'otp_verified', 'password_required', 'authenticated', 'expired')",
      name: "chk_auth_transactions_state"

    add_check_constraint :auth_transactions,
      "selected_method IS NULL OR selected_method IN ('otp', 'password')",
      name: "chk_auth_transactions_method"

    add_check_constraint :auth_transactions,
      "expires_at > created_at",
      name: "chk_auth_transactions_expiry"

    add_index :auth_transactions, :identifier,
              name: "auth_transactions_identifier_idx"

    add_index :auth_transactions, :user_id,
              name: "auth_transactions_user_id_idx"

    add_index :auth_transactions, [:identifier, :expires_at],
              where: "state NOT IN ('authenticated', 'expired')",
              name: "auth_transactions_active_idx"

    create_table :auth_challenges, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references  :auth_transaction, type: :uuid, foreign_key: { on_delete: :cascade }
      t.citext      :identifier,       null: false
      t.text        :secret_hash,      null: false
      t.text        :purpose,          null: false
      t.jsonb       :state,            null: false, default: {}
      t.integer     :attempts,         null: false, default: 0
      t.integer     :max_attempts,     null: false, default: 5
      t.timestamptz :expires_at,       null: false
      t.timestamptz :consumed_at
      t.timestamptz :created_at,       null: false, default: -> { "now()" }
    end

    add_check_constraint :auth_challenges,
      "purpose IN ('email_otp', 'email_verification', 'password_reset', 'magic_link')",
      name: "chk_auth_challenges_purpose"

    add_check_constraint :auth_challenges,
      "jsonb_typeof(state) = 'object'",
      name: "chk_auth_challenges_state"

    add_check_constraint :auth_challenges,
      "attempts >= 0",
      name: "chk_auth_challenges_attempts"

    add_check_constraint :auth_challenges,
      "max_attempts > 0",
      name: "chk_auth_challenges_max_attempts"

    add_check_constraint :auth_challenges,
      "expires_at > created_at",
      name: "chk_auth_challenges_expiry"

    add_check_constraint :auth_challenges,
      "consumed_at IS NULL OR consumed_at >= created_at",
      name: "chk_auth_challenges_consumed"

    add_index :auth_challenges, :auth_transaction_id,
              name: "auth_challenges_transaction_idx"

    add_index :auth_challenges, :identifier,
              name: "auth_challenges_identifier_idx"

    add_index :auth_challenges, [:identifier, :purpose, :expires_at],
              where: "consumed_at IS NULL",
              name: "auth_challenges_active_idx"

    add_index :auth_challenges, :expires_at,
              where: "consumed_at IS NULL",
              name: "auth_challenges_expires_idx"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TRIGGER trg_auth_transactions_set_updated_at
          BEFORE UPDATE ON auth_transactions
          FOR EACH ROW
          EXECUTE FUNCTION set_updated_at();
        SQL
      end

      dir.down do
        execute "DROP TRIGGER IF EXISTS trg_auth_transactions_set_updated_at ON auth_transactions;"
      end
    end
  end
end