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

ActiveRecord::Schema.define(version: 20141116101522) do

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

# Could not dump table "users" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

end
