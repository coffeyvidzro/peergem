# frozen_string_literal: true

class CreateSecurityEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :security_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, foreign_key: { on_delete: :nullify }
      t.string :event_type, null: false
      t.inet :ip_address
      t.text :user_agent
      t.jsonb :metadata, null: false, default: {}
      t.timestamptz :occurred_at, null: false, default: -> { "now()" }
    end

    add_check_constraint :security_events,
      "jsonb_typeof(metadata) = 'object'",
      name: "chk_security_events_metadata"
    add_index :security_events, [ :user_id, :occurred_at ]
    add_index :security_events, [ :event_type, :occurred_at ]
    add_index :security_events, :occurred_at
  end
end