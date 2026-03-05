# frozen_string_literal: true

class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :notification_event_types, array: true, default: GithubWebhookEvent::SUPPORTED_EVENTS
      t.boolean :email_digest_enabled, default: false, null: false
      t.string :email_digest_frequency, default: "weekly", null: false
      t.timestamps
    end
  end
end
