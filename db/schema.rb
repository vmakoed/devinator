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

ActiveRecord::Schema[8.0].define(version: 2025_09_30_095319) do
  create_table "missions", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "jql_query"
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
    t.index ["mission_id", "jira_key"], name: "index_tickets_on_mission_id_and_jira_key", unique: true
    t.index ["mission_id"], name: "index_tickets_on_mission_id"
  end

  add_foreign_key "tickets", "missions"
end
