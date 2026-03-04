# frozen_string_literal: true

class CreateGithubWebhookEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :github_webhook_events do |t|
      t.string :event_type, null: false
      t.string :action
      t.string :delivery_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.datetime :processed_at
      t.text :error_message

      t.timestamps
    end

    add_index :github_webhook_events, :delivery_id, unique: true
    add_index :github_webhook_events, :status
    add_index :github_webhook_events, :event_type
  end
end
