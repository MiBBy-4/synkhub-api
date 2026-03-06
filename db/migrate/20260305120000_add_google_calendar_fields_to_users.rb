# frozen_string_literal: true

class AddGoogleCalendarFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :google_email, :string
    add_column :users, :google_access_token, :string
    add_column :users, :google_refresh_token, :string
    add_column :users, :google_token_expires_at, :datetime
    add_column :users, :google_token_scope, :string

    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
  end
end
