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

ActiveRecord::Schema[7.2].define(version: 2026_03_31_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.string "loggable_type", null: false
    t.bigint "loggable_id", null: false
    t.string "action", null: false
    t.jsonb "metadata", default: {}
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
    t.string "license_number"
    t.string "background_check_id"
    t.boolean "insurance_verified"
    t.jsonb "compliance_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "risk_score", default: 0
    t.jsonb "risk_flags", default: []
    t.datetime "last_assessed_at"
    t.string "background_check_status"
    t.index ["license_number"], name: "index_providers_on_license_number", unique: true, where: "((license_number IS NOT NULL) AND ((license_number)::text <> ''::text))"
    t.index ["risk_flags"], name: "index_providers_on_risk_flags", using: :gin
    t.index ["risk_score"], name: "index_providers_on_risk_score"
  end

  create_table "violations", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "category", null: false
    t.string "severity", null: false
    t.text "description"
    t.boolean "resolved", default: false, null: false
    t.date "occurred_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_violations_on_provider_id"
  end

  add_foreign_key "violations", "providers"
end
