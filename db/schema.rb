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

ActiveRecord::Schema[8.0].define(version: 2025_09_30_141758) do
  create_table "missions", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "jql_query"
    t.datetime "assigned_at"
    t.datetime "assignment_completed_at"
    t.integer "total_assigned_count", default: 0, null: false
    t.integer "failed_assignment_count", default: 0, null: false
  end

  create_table "tickets", id: :string, force: :cascade do |t|
    t.string "mission_id", null: false
    t.string "jira_key", null: false
    t.string "summary", null: false
    t.text "description"
    t.string "status", null: false
    t.string "priority"
    t.string "assignee"
    t.text "labels"
    t.datetime "jira_created_at"
    t.json "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complexity_score"
    t.string "complexity_category"
    t.json "complexity_factors"
    t.datetime "analyzed_at"
    t.boolean "selected_for_assignment", default: false, null: false
    t.datetime "selected_at"
    t.string "devin_session_id"
    t.string "devin_session_url"
    t.datetime "assigned_to_devin_at"
    t.string "assignment_status", default: "pending", null: false
    t.text "assignment_error"
    t.integer "assignment_retry_count", default: 0, null: false
    t.index ["mission_id", "jira_key"], name: "index_tickets_on_mission_id_and_jira_key", unique: true
    t.index ["mission_id"], name: "index_tickets_on_mission_id"
  end

  add_foreign_key "tickets", "missions"
end
