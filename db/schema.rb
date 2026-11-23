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

ActiveRecord::Schema[8.1].define(version: 2026_11_23_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_push_native_devices", force: :cascade do |t|
    t.string "name"
    t.string "platform", null: false
    t.string "token", null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_action_push_native_devices_on_owner"
    t.index ["token"], name: "index_action_push_native_devices_on_token", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "household_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "household_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "digest", default: true, null: false
    t.index ["household_id"], name: "index_household_members_on_household_id"
    t.index ["user_id", "household_id"], name: "index_household_members_on_user_id_and_household_id", unique: true
  end

  create_table "households", force: :cascade do |t|
    t.string "name", null: false
    t.string "time_zone", default: "Indian/Reunion", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.integer "altitude_m"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.string "name", null: false
    t.string "exposure", null: false
    t.boolean "sheltered", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "rain_exposed", default: false, null: false
    t.index ["household_id", "name"], name: "index_locations_on_household_id_and_name", unique: true
  end

  create_table "photos", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.datetime "taken_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_id", "taken_at"], name: "index_photos_on_plant_id_and_taken_at"
  end

  create_table "plant_analyses", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.bigint "requested_by_id"
    t.string "status", default: "pending", null: false
    t.text "user_note"
    t.string "health"
    t.string "species_name"
    t.string "species_common_name"
    t.string "species_confidence"
    t.integer "watering_interval_days"
    t.text "observations"
    t.jsonb "actions", default: [], null: false
    t.string "error"
    t.string "model"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "applied_action_indexes", default: [], null: false, array: true
    t.jsonb "place"
    t.index ["plant_id", "created_at"], name: "index_plant_analyses_on_plant_id_and_created_at"
    t.index ["plant_id"], name: "index_plant_analyses_one_pending", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["requested_by_id"], name: "index_plant_analyses_on_requested_by_id"
  end

  create_table "plant_analysis_photos", force: :cascade do |t|
    t.bigint "plant_analysis_id", null: false
    t.bigint "photo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["photo_id"], name: "index_plant_analysis_photos_on_photo_id"
    t.index ["plant_analysis_id", "photo_id"], name: "index_plant_analysis_photos_on_plant_analysis_id_and_photo_id", unique: true
  end

  create_table "plant_analysis_questions", force: :cascade do |t|
    t.bigint "plant_analysis_id", null: false
    t.bigint "asked_by_id"
    t.bigint "photo_id"
    t.text "body", null: false
    t.string "status", default: "pending", null: false
    t.text "answer"
    t.string "error"
    t.string "model"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asked_by_id"], name: "index_plant_analysis_questions_on_asked_by_id"
    t.index ["photo_id"], name: "index_plant_analysis_questions_on_photo_id"
    t.index ["plant_analysis_id", "created_at"], name: "idx_on_plant_analysis_id_created_at_c4c13f2068"
    t.index ["plant_analysis_id"], name: "index_plant_analysis_questions_one_pending", unique: true, where: "((status)::text = 'pending'::text)"
  end

  create_table "plants", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.bigint "location_id"
    t.string "name", null: false
    t.string "species"
    t.string "species_source"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cover_photo_id"
    t.index ["cover_photo_id"], name: "index_plants_on_cover_photo_id"
    t.index ["household_id"], name: "index_plants_on_household_id"
    t.index ["location_id"], name: "index_plants_on_location_id"
  end

  create_table "rainfalls", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.date "fell_on", null: false
    t.decimal "millimeters", precision: 5, scale: 1, null: false
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id", "fell_on"], name: "index_rainfalls_on_household_id_and_fell_on", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "task_occurrences", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.datetime "due_at", null: false
    t.string "status", default: "pending", null: false
    t.bigint "completed_by_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reopened_after_miss", default: false, null: false
    t.string "source", default: "manual", null: false
    t.index ["completed_by_id"], name: "index_task_occurrences_on_completed_by_id"
    t.index ["task_id", "due_at"], name: "index_task_occurrences_on_task_id_and_due_at"
    t.index ["task_id"], name: "index_task_occurrences_one_pending", unique: true, where: "((status)::text = 'pending'::text)"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "title", null: false
    t.string "template_key"
    t.string "recurrence_type", null: false
    t.jsonb "recurrence_config", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "importance", default: "flexible", null: false
    t.text "instructions"
    t.string "suggestion_key"
    t.index ["household_id"], name: "index_tasks_on_household_id"
    t.index ["subject_type", "subject_id"], name: "index_tasks_on_subject"
    t.check_constraint "(subject_type IS NULL) = (subject_id IS NULL)", name: "tasks_subject_whole_or_none"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "digest_enabled", default: true, null: false
    t.integer "digest_minute", default: 480, null: false
    t.date "last_digest_on"
    t.string "digest_scope", default: "all", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "household_members", "households"
  add_foreign_key "household_members", "users"
  add_foreign_key "locations", "households"
  add_foreign_key "photos", "plants"
  add_foreign_key "plant_analyses", "plants"
  add_foreign_key "plant_analyses", "users", column: "requested_by_id"
  add_foreign_key "plant_analysis_photos", "photos"
  add_foreign_key "plant_analysis_photos", "plant_analyses"
  add_foreign_key "plant_analysis_questions", "photos", on_delete: :nullify
  add_foreign_key "plant_analysis_questions", "plant_analyses"
  add_foreign_key "plant_analysis_questions", "users", column: "asked_by_id"
  add_foreign_key "plants", "households"
  add_foreign_key "plants", "locations"
  add_foreign_key "plants", "photos", column: "cover_photo_id", on_delete: :nullify
  add_foreign_key "rainfalls", "households"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_occurrences", "tasks"
  add_foreign_key "task_occurrences", "users", column: "completed_by_id"
  add_foreign_key "tasks", "households"
end
