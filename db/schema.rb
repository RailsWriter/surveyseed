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

ActiveRecord::Schema.define(version: 20141109033158) do

  create_table "leads", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "phone"
  end

  create_table "users", force: true do |t|
    t.integer  "birth_month"
    t.integer  "birth_year"
    t.boolean  "tos"
    t.string   "gender"
    t.string   "country"
    t.string   "ZIP"
    t.string   "ethnicity"
    t.string   "race"
    t.string   "eduation"
    t.integer  "householdcomp"
    t.string   "householdincome"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "session_id"
    t.string   "ip_address"
    t.string   "user_agent"
  end

end
