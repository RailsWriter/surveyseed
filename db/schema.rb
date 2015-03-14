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

ActiveRecord::Schema.define(version: 20150312025725) do

  create_table "leads", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "phone"
  end

  create_table "networks", force: true do |t|
    t.string   "name"
    t.string   "netid"
    t.float    "payout"
    t.string   "status"
    t.text     "testcompletes", limit: 5000000
    t.text     "completes",     limit: 50000000
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "Flag1"
    t.string   "Flag2"
    t.string   "Flag3"
    t.string   "Flag4"
    t.string   "Flag5"
    t.integer  "P2S_US"
    t.integer  "P2S_CA"
    t.integer  "P2S_AU"
  end

  create_table "rfg_projects", force: true do |t|
    t.string   "rfg_id"
    t.string   "title"
    t.string   "country"
    t.string   "cpi"
    t.integer  "estimatedIR"
    t.integer  "estimatedLOI"
    t.datetime "endOfField"
    t.integer  "desiredCompletes"
    t.integer  "currentCompletes"
    t.boolean  "collectsPII"
    t.integer  "state"
    t.text     "datapoints"
    t.datetime "lastModified"
    t.string   "duplicationKey"
    t.integer  "filterMode"
    t.boolean  "isRecontact"
    t.string   "mobileOptimized"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "surveys", force: true do |t|
    t.string   "SurveyName"
    t.integer  "SurveyNumber"
    t.string   "SurveySID"
    t.string   "AccountName"
    t.integer  "CountryLanguageID"
    t.integer  "LengthOfInterview"
    t.float    "BidIncidence"
    t.integer  "Conversion"
    t.float    "CPI"
    t.datetime "FieldEndDate"
    t.integer  "IndustryID"
    t.integer  "StudyTypeID"
    t.integer  "OverallCompletes"
    t.integer  "TotalRemaining"
    t.integer  "CompletionPercentage"
    t.string   "SurveyGroup"
    t.integer  "BidLengthOfInterview"
    t.integer  "TerminationLengthOfInterview"
    t.string   "IsTrueSample"
    t.integer  "SurveyMobileConversion"
    t.integer  "SurveyQuotaCalcTypeID"
    t.integer  "SampleTypeID"
    t.text     "QualificationAgePreCodes"
    t.text     "QualificationGenderPreCodes"
    t.text     "QualificationZIPPreCodes",        limit: 1000000
    t.text     "QualificationHHIPreCodes"
    t.text     "QualificationEducationPreCodes"
    t.text     "QualificationHHCPreCodes"
    t.text     "QualificationEthnicityPreCodes"
    t.text     "QualificationRacePreCodes"
    t.text     "SurveyQuotas",                    limit: 50000000
    t.string   "SurveyStatusCode"
    t.boolean  "SurveyStillLive"
    t.integer  "SurveyGrossRank"
    t.integer  "SurveyExactRank"
    t.text     "SupplierLink"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.text     "CompletedBy"
    t.float    "KEPC"
    t.float    "GEPC"
    t.integer  "FailureCount"
    t.integer  "OverQuotaCount"
    t.integer  "NumberofAttemptsAtLastComplete"
    t.float    "TCR"
    t.string   "label"
    t.text     "QualificationEmploymentPreCodes"
    t.text     "QualificationPIndustryPreCodes"
    t.text     "QualificationDMAPreCodes"
    t.text     "QualificationStatePreCodes"
    t.text     "QualificationRegionPreCodes"
    t.text     "QualificationDivisionPreCodes"
    t.text     "QualificationJobTitlePreCodes"
    t.text     "QualificationChildrenPreCodes"
  end

  create_table "us_geos", force: true do |t|
    t.string   "zip"
    t.string   "zip_type"
    t.string   "primary_city"
    t.string   "county"
    t.string   "timezone"
    t.string   "area_codes"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "world_region"
    t.string   "country"
    t.boolean  "decommissioned"
    t.integer  "estimated_population"
    t.string   "City"
    t.string   "CriteriaID"
    t.string   "State"
    t.string   "StateAbrv"
    t.string   "DMARegion"
    t.string   "DMARegionCode"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "region"
    t.string   "regionPrecode"
    t.string   "division"
    t.string   "divisionPrecode"
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
    t.string   "age"
    t.text     "SupplierLink"
    t.text     "QualifiedSurveys"
    t.text     "SurveysWithMatchingQuota"
    t.integer  "birth_date"
    t.float    "currentpayout"
    t.text     "SurveysAttempted"
    t.text     "SurveysCompleted"
    t.string   "netid"
    t.string   "clickid"
    t.string   "pindustry"
    t.string   "employment"
    t.string   "jobtitle"
    t.text     "children"
  end

end
