# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160302173527) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "cluster_groups", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "name"
    t.jsonb    "user_uuids"
    t.jsonb    "cluster_results"
    t.uuid     "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datasource_accesses", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "research_case_id"
    t.string   "datasource_key"
    t.string   "channel"
    t.datetime "accessed_at",      default: '2016-02-11 16:34:02', null: false
  end

  create_table "datasources", id: false, force: :cascade do |t|
    t.string "key",         null: false
    t.string "name"
    t.text   "description"
    t.text   "settings"
    t.string "type"
  end

  add_index "datasources", ["key"], name: "index_datasources_on_key", unique: true, using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "user_uuid"
    t.integer  "verb_id"
    t.integer  "resource_id"
    t.jsonb    "in_context"
    t.jsonb    "with_result"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "research_cases", force: :cascade do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "research_cases_users", id: false, force: :cascade do |t|
    t.integer "research_case_id"
    t.integer "user_id"
  end

  add_index "research_cases_users", ["research_case_id", "user_id"], name: "index_research_cases_users_on_research_case_id_and_user_id", using: :btree

  create_table "resources", force: :cascade do |t|
    t.string   "uuid"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teacher_actions", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.uuid     "cluster_group_id"
    t.uuid     "author_id"
    t.uuid     "richtext_id"
    t.jsonb    "subject"
    t.jsonb    "user_uuids"
    t.datetime "action_performed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "half_group"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",            null: false
    t.string   "crypted_password", null: false
    t.string   "salt",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "verbs", force: :cascade do |t|
    t.string   "verb"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
