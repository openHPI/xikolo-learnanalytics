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

ActiveRecord::Schema.define(version: 20141216161312) do

  create_table "datasources", id: false, force: true do |t|
    t.string   "key",         null: false
    t.string   "name"
    t.string   "description"
    t.string   "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
  end

  add_index "datasources", ["key"], name: "index_datasources_on_key", unique: true

  create_table "research_cases", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "research_cases_users", id: false, force: true do |t|
    t.integer "research_case_id"
    t.integer "user_id"
  end

  add_index "research_cases_users", ["research_case_id", "user_id"], name: "index_research_cases_users_on_research_case_id_and_user_id"

  create_table "users", force: true do |t|
    t.string   "email",            null: false
    t.string   "crypted_password", null: false
    t.string   "salt",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

end
