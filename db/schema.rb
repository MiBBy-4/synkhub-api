# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_04_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "github_notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "github_webhook_event_id", null: false
    t.string "event_type", null: false
    t.string "action"
    t.string "title", null: false
    t.string "url"
    t.string "repo_full_name", null: false
    t.string "actor_login", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_webhook_event_id"], name: "index_github_notifications_on_github_webhook_event_id"
    t.index ["user_id", "created_at"], name: "index_github_notifications_on_user_id_and_created_at"
    t.index ["user_id", "github_webhook_event_id"], name: "idx_on_user_id_github_webhook_event_id_3298199074", unique: true
    t.index ["user_id", "read"], name: "index_github_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_github_notifications_on_user_id"
  end

  create_table "github_repo_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "github_repo_id", null: false
    t.string "repo_full_name", null: false
    t.bigint "webhook_github_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_repo_id"], name: "index_github_repo_subscriptions_on_github_repo_id"
    t.index ["user_id", "github_repo_id"], name: "index_github_repo_subscriptions_on_user_id_and_github_repo_id", unique: true
    t.index ["user_id"], name: "index_github_repo_subscriptions_on_user_id"
  end

  create_table "github_webhook_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.string "action"
    t.string "delivery_id", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "processed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_github_webhook_events_on_delivery_id", unique: true
    t.index ["event_type"], name: "index_github_webhook_events_on_event_type"
    t.index ["status"], name: "index_github_webhook_events_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "github_uid"
    t.string "github_username"
    t.string "github_access_token"
    t.string "github_token_scope"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true, where: "(github_uid IS NOT NULL)"
  end

  add_foreign_key "github_notifications", "github_webhook_events"
  add_foreign_key "github_notifications", "users"
  add_foreign_key "github_repo_subscriptions", "users"
end
