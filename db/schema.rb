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

ActiveRecord::Schema[8.0].define(version: 2025_09_29_130601) do
  create_table "assignments", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "ticket_id", null: false
    t.string "assignee_type"
    t.string "assignee_id"
    t.datetime "assigned_at"
    t.string "status"
    t.text "assignment_message"
    t.text "assignment_metadata"
    t.integer "created_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_assignments_on_created_by_user_id"
    t.index ["session_id"], name: "index_assignments_on_session_id"
    t.index ["ticket_id"], name: "index_assignments_on_ticket_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "session_id", null: false
    t.string "entity_type"
    t.string "entity_id"
    t.string "action"
    t.text "old_values"
    t.text "new_values"
    t.integer "user_id", null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_audit_logs_on_session_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "complexity_analyses", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.decimal "complexity_score"
    t.string "complexity_level"
    t.text "scoring_details"
    t.text "heuristics_applied"
    t.datetime "analyzed_at"
    t.string "analysis_version"
    t.boolean "is_manual_override"
    t.text "override_reason"
    t.integer "overridden_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["overridden_by_user_id"], name: "index_complexity_analyses_on_overridden_by_user_id"
    t.index ["ticket_id"], name: "index_complexity_analyses_on_ticket_id"
  end

  create_table "complexity_criteria", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "criteria_config"
    t.decimal "weight"
    t.boolean "is_active"
    t.integer "created_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_complexity_criteria_on_created_by_user_id"
  end

  create_table "jql_queries", force: :cascade do |t|
    t.integer "session_id", null: false
    t.text "query_text"
    t.datetime "executed_at"
    t.string "status"
    t.integer "ticket_count"
    t.text "parameters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.text "description"
    t.index ["session_id"], name: "index_jql_queries_on_session_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "ticket_id", null: false
    t.string "recommendation_type"
    t.decimal "confidence_score"
    t.text "reasoning"
    t.boolean "is_suitable_for_devin"
    t.text "recommendation_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_recommendations_on_session_id"
    t.index ["ticket_id"], name: "index_recommendations_on_ticket_id"
  end

  create_table "session_configurations", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "user_id", null: false
    t.string "configuration_name"
    t.text "jql_templates"
    t.text "complexity_settings"
    t.text "notification_settings"
    t.boolean "is_default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_session_configurations_on_session_id"
    t.index ["user_id"], name: "index_session_configurations_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.text "description"
    t.string "status"
    t.text "configuration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.integer "session_id", null: false
    t.string "jira_key"
    t.string "jira_id"
    t.string "title"
    t.text "description"
    t.string "status"
    t.string "priority"
    t.string "issue_type"
    t.text "labels"
    t.string "assignee"
    t.string "reporter"
    t.datetime "created_date"
    t.datetime "updated_date"
    t.text "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_tickets_on_session_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "password_hash"
    t.string "role"
    t.text "jira_credentials"
    t.text "preferences"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "assignments", "sessions"
  add_foreign_key "assignments", "tickets"
  add_foreign_key "assignments", "users", column: "created_by_user_id"
  add_foreign_key "audit_logs", "sessions"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "complexity_analyses", "tickets"
  add_foreign_key "complexity_analyses", "users", column: "overridden_by_user_id"
  add_foreign_key "complexity_criteria", "users", column: "created_by_user_id"
  add_foreign_key "jql_queries", "sessions"
  add_foreign_key "recommendations", "sessions"
  add_foreign_key "recommendations", "tickets"
  add_foreign_key "session_configurations", "sessions"
  add_foreign_key "session_configurations", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tickets", "sessions"
end
