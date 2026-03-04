# frozen_string_literal: true

class CreateGithubRepoSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :github_repo_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :github_repo_id, null: false
      t.string :repo_full_name, null: false
      t.bigint :webhook_github_id

      t.timestamps
    end

    add_index :github_repo_subscriptions, [:user_id, :github_repo_id], unique: true
    add_index :github_repo_subscriptions, :github_repo_id
  end
end
