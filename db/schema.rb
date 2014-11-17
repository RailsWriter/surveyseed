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

ActiveRecord::Schema.define(version: 20141117001500) do

  create_table "leads", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "phone"
  end

  create_table "us_geos", force: true do |t|
    t.string   "zip"
    t.string   "zip_type"
    t.string   "primary_city"
    t.string   "acceptable_cities"
    t.string   "unacceptable_cities"
    t.string   "county"
    t.string   "timezone"
    t.string   "area_codes"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "world_region"
    t.string   "country"
    t.boolean  "decommissioned"
    t.integer  "estimated_population"
    t.string   "notes"
    t.string   "City"
    t.string   "CriteriaID"
    t.string   "State"
    t.string   "StateAbrv"
    t.string   "DMARegion"
    t.string   "DMARegionCode"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
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
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "session_id"
    t.string   "ip_address"
    t.string   "user_agent"
    t.string   "trap_question_1_response"
    t.string   "trap_question_2a_response"
    t.string   "trap_question_2b_response"
    t.boolean  "watch_listed"
    t.boolean  "black_listed"
    t.string   "user_id"
    t.integer  "number_of_attempts_in_last_24hrs"
    t.text     "attempts_time_stamps_array"
  end

end
