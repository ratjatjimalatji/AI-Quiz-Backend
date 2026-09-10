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

ActiveRecord::Schema[8.1].define(version: 2026_09_09_080232) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "current_question_id"
    t.bigint "current_round_id"
    t.string "game_code"
    t.integer "host_id", null: false
    t.integer "player_limit", default: 8, null: false
    t.datetime "question_started_at"
    t.string "status", default: "waiting"
    t.datetime "updated_at", null: false
    t.index ["current_question_id"], name: "index_games_on_current_question_id"
    t.index ["current_round_id"], name: "index_games_on_current_round_id"
    t.index ["host_id"], name: "index_games_on_host_id"
  end

  create_table "hosts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_hosts_on_token", unique: true
  end

  create_table "options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.integer "question_id", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "position"], name: "index_options_on_question_id_and_position"
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "eliminated", default: false
    t.integer "game_id"
    t.integer "score", default: 0
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["token"], name: "index_players_on_token", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.json "correct_answer_ids", default: []
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "question_type", default: 0, null: false
    t.integer "round_id"
    t.datetime "shown_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_questions_on_round_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id"
    t.integer "position", default: 0
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "position"], name: "index_rounds_on_game_id_and_position"
    t.index ["game_id"], name: "index_rounds_on_game_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "submissions", force: :cascade do |t|
    t.jsonb "answer"
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.integer "points_awarded", null: false
    t.bigint "question_id", null: false
    t.integer "response_time_ms", null: false
    t.bigint "round_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "question_id", "round_id"], name: "index_submissions_on_player_id_and_question_id_and_round_id", unique: true
    t.index ["player_id"], name: "index_submissions_on_player_id"
    t.index ["question_id"], name: "index_submissions_on_question_id"
    t.index ["round_id"], name: "index_submissions_on_round_id"
  end

  add_foreign_key "games", "hosts"
  add_foreign_key "games", "questions", column: "current_question_id"
  add_foreign_key "games", "rounds", column: "current_round_id"
  add_foreign_key "options", "questions"
  add_foreign_key "players", "games"
  add_foreign_key "questions", "rounds"
  add_foreign_key "rounds", "games"
  add_foreign_key "submissions", "players"
  add_foreign_key "submissions", "questions"
  add_foreign_key "submissions", "rounds"
end
