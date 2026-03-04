# frozen_string_literal: true

class CreateGithubNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :github_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :github_webhook_event, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :action
      t.string :title, null: false
      t.string :url
      t.string :repo_full_name, null: false
      t.string :actor_login, null: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :github_notifications, [:user_id, :read]
    add_index :github_notifications, [:user_id, :created_at]
    add_index :github_notifications, [:user_id, :github_webhook_event_id], unique: true
  end
end
