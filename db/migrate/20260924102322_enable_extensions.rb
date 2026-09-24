# frozen_string_literal: true

class EnableExtensions < ActiveRecord::Migration[8.1]
  def up
    enable_extension "citext"
    enable_extension "pgcrypto"

    execute <<~SQL
      CREATE OR REPLACE FUNCTION set_updated_at()
      RETURNS trigger AS $$
      BEGIN
        NEW.updated_at = now();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute "DROP FUNCTION IF EXISTS set_updated_at();"
    disable_extension "pgcrypto"
    disable_extension "citext"
  end
end
