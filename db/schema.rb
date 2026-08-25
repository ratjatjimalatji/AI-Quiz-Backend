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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_091546) do
  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "game_code"
    t.integer "host_id", null: false
    t.integer "player_limit"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_games_on_host_id"
  end

  create_table "hosts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token"], name: "index_hosts_on_token", unique: true
    t.index ["user_id"], name: "index_hosts_on_user_id"
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
    t.boolean "eliminated"
    t.integer "game_id"
    t.integer "score"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["game_id"], name: "index_players_on_game_id"
  end

  create_table "questions", force: :cascade do |t|
    t.json "correct_answer_ids", default: []
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "question_type", default: 0, null: false
    t.integer "round_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_questions_on_round_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "round_type", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_rounds_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "games", "hosts"
  add_foreign_key "hosts", "users"
  add_foreign_key "options", "questions"
  add_foreign_key "players", "games"
  add_foreign_key "questions", "rounds"
  add_foreign_key "rounds", "games"
end
