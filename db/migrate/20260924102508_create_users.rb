# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.citext      :email,             null: false
      t.text        :name
      t.text        :password_digest
      t.boolean     :is_platform_admin, null: false, default: false
      t.timestamptz :confirmed_at
      t.integer     :failed_attempts,   null: false, default: 0
      t.timestamptz :disabled_at
      t.timestamptz :created_at,        null: false, default: -> { "now()" }
      t.timestamptz :updated_at,        null: false, default: -> { "now()" }
    end

    add_check_constraint :users,
      "failed_attempts >= 0",
      name: "chk_users_failed_attempts"

    # Unique index on citext email handles case-insensitive uniqueness natively
    add_index :users, :email,
              unique: true,
              name: "users_email_idx"

    # Index unconfirmed users if background cleanup/reminders target them
    add_index :users, :confirmed_at,
              where: "confirmed_at IS NULL",
              name: "users_unconfirmed_idx"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TRIGGER trg_users_set_updated_at
          BEFORE UPDATE ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_updated_at();
        SQL
      end

      dir.down do
        execute "DROP TRIGGER IF EXISTS trg_users_set_updated_at ON users;"
      end
    end
  end
end