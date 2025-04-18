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

ActiveRecord::Schema[7.2].define(version: 2025_02_21_154821) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "course_statistics", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "course_code"
    t.string "course_status"
    t.uuid "course_id"
    t.integer "total_enrollments"
    t.integer "no_shows"
    t.integer "current_enrollments"
    t.integer "enrollments_last_day"
    t.integer "enrollments_at_course_start"
    t.integer "enrollments_at_course_middle"
    t.integer "enrollments_at_course_end"
    t.integer "questions"
    t.integer "questions_last_day"
    t.integer "answers"
    t.integer "answers_last_day"
    t.integer "comments_on_answers"
    t.integer "comments_on_answers_last_day"
    t.integer "comments_on_questions"
    t.integer "comments_on_questions_last_day"
    t.integer "roa_count"
    t.integer "helpdesk_tickets"
    t.integer "helpdesk_tickets_last_day"
    t.float "completion_rate"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.integer "new_users"
    t.json "enrollments_per_day"
    t.boolean "hidden"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "days_since_coursestart"
    t.integer "questions_in_learning_rooms"
    t.integer "questions_last_day_in_learning_rooms"
    t.integer "answers_in_learning_rooms"
    t.integer "answers_last_day_in_learning_rooms"
    t.integer "comments_on_answers_in_learning_rooms"
    t.integer "comments_on_answers_last_day_in_learning_rooms"
    t.integer "comments_on_questions_in_learning_rooms"
    t.integer "comments_on_questions_last_day_in_learning_rooms"
    t.integer "enrollments_at_course_start_netto"
    t.integer "enrollments_at_course_middle_netto"
    t.integer "enrollments_at_course_end_netto"
    t.integer "shows"
    t.integer "shows_at_middle"
    t.integer "shows_at_end"
    t.integer "no_shows_at_middle"
    t.integer "no_shows_at_end"
    t.integer "badge_issues", default: 0
    t.integer "badge_downloads", default: 0
    t.integer "badge_shares", default: 0
    t.integer "active_users_last_day", default: 0
    t.integer "active_users_last_7days", default: 0
    t.integer "cop_count"
    t.integer "qc_count"
    t.float "consumption_rate"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "user_uuid"
    t.integer "verb_id"
    t.integer "resource_id"
    t.jsonb "in_context"
    t.jsonb "with_result"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index "((in_context ->> 'course_id'::text))", name: "events_in_context_course_id"
  end

  create_table "profile_fields", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "sensitive", default: false, null: false
    t.boolean "omittable", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "report_jobs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "task_type"
    t.string "task_scope"
    t.string "status"
    t.string "job_params"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "user_id"
    t.datetime "file_expire_date", precision: nil
    t.integer "progress"
    t.string "annotation"
    t.text "error_text"
    t.string "download_url"
    t.jsonb "options", default: {}, null: false
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "resource_type"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "verbs", id: :serial, force: :cascade do |t|
    t.string "verb"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at", precision: nil
    t.json "object"
    t.uuid "item_id", null: false
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end
end
