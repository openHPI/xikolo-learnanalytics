# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_18_101622) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "cluster_groups", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "user_uuids"
    t.jsonb "cluster_results"
    t.uuid "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.integer "certificates"
    t.integer "helpdesk_tickets"
    t.integer "helpdesk_tickets_last_day"
    t.float "completion_rate"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "new_users"
    t.json "enrollments_per_day"
    t.boolean "hidden"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "datasource_accesses", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "research_case_id"
    t.string "datasource_key"
    t.string "channel"
    t.datetime "accessed_at", default: "1970-01-01 00:00:00", null: false
  end

  create_table "datasources", primary_key: "key", id: :string, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "settings"
    t.string "type"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "user_uuid"
    t.integer "verb_id"
    t.integer "resource_id"
    t.jsonb "in_context"
    t.jsonb "with_result"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index "((in_context ->> 'course_id'::text))", name: "events_in_context_course_id"
  end

  create_table "profile_fields", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "sensitive", default: false, null: false
    t.boolean "omittable", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "qc_alert_statuses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "qc_alert_id"
    t.uuid "user_id"
    t.boolean "ignored"
    t.boolean "ack"
    t.boolean "muted"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_alerts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "qc_rule_id"
    t.string "status"
    t.uuid "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "severity"
    t.text "annotation"
    t.json "qc_alert_data"
    t.boolean "is_global_ignored", default: false, null: false
  end

  create_table "qc_course_statuses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "qc_rule_id"
    t.uuid "course_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_recommendations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "qc_alert_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qc_rules", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "worker"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_active"
    t.boolean "is_global"
  end

  create_table "report_jobs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "task_type"
    t.string "task_scope"
    t.string "status"
    t.string "job_params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "user_id"
    t.datetime "file_expire_date"
    t.integer "progress"
    t.string "annotation"
    t.text "error_text"
    t.string "download_url"
    t.jsonb "options", default: {}, null: false
  end

  create_table "research_cases", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "description"
  end

  create_table "research_cases_users", primary_key: ["research_case_id", "user_id"], force: :cascade do |t|
    t.integer "research_case_id", null: false
    t.integer "user_id", null: false
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teacher_actions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "cluster_group_id"
    t.uuid "author_id"
    t.uuid "richtext_id"
    t.jsonb "subject"
    t.jsonb "user_uuids"
    t.datetime "action_performed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "half_group", default: false, null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password", null: false
    t.string "salt", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "verbs", id: :serial, force: :cascade do |t|
    t.string "verb"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at"
    t.json "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
