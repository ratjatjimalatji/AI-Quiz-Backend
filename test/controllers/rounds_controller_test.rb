# test/models/game_test.rb
require "test_helper"
require "minitest/mock"

class GameTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  # ---------------------------------------------------------------------------
  # Fixtures note:
  #   Fixtures are inserted straight into the DB, so `after_create :populate_quiz_data`
  #   does NOT run. games(:empty) therefore starts with zero rounds/questions, and each
  #   test builds exactly the rounds it needs with `build_rounds`.
  #
  #   DisplayLeaderboardService and RoundTransitionService are stubbed in flow tests so
  #   we test the Game state machine in isolation. RoundTransitionService has its own
  #   tests at the bottom (with RoundResultsService stubbed).
  # ---------------------------------------------------------------------------

  setup do
    @game = games(:empty)
    @leaderboard_calls = []
    @transition_calls = []
  end

  # ===========================================================================
  # Fixtures sanity
  # ===========================================================================

  test "fixtures: game one has four players" do
    assert_equal 4, games(:one).players.count
    assert_equal %w[User1 User2 User3 User4], games(:one).players.order(:username).pluck(:username)
  end

  test "fixtures: games start in waiting" do
    assert games(:one).waiting?
    assert games(:two).waiting?
    assert games(:empty).waiting?
  end

  test "fixtures: empty game has no rounds" do
    assert_empty @game.rounds
  end

  # ===========================================================================
  # Validations & callbacks
  # ===========================================================================

  test "game_code is required and unique" do
    duplicate = Game.new(host: hosts(:one), player_limit: 5, game_code: games(:one).game_code)
    # generate_game_code runs before_validation on create and overwrites, so check the DB-level rule explicitly
    duplicate.define_singleton_method(:generate_game_code) { }
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:game_code], "has already been taken"
  end

  test "player_limit must be greater than zero" do
    @game.player_limit = 0
    assert_not @game.valid?
    assert @game.errors[:player_limit].any?

    @game.player_limit = 1
    assert @game.valid?
  end

  test "generate_game_code creates a 6 character uppercase hex code on create" do
    QuizPopulator.stub(:call, true) do
      game = Game.create!(host: hosts(:one), player_limit: 4)
      assert_match(/\A[0-9A-F]{6}\z/, game.game_code)
    end
  end

  test "populate_quiz_data runs after create" do
    called_with = nil
    QuizPopulator.stub(:call, ->(game) { called_with = game }) do
      game = Game.create!(host: hosts(:one), player_limit: 4)
      assert_equal game, called_with
    end
  end

  test "default status is waiting" do
    QuizPopulator.stub(:call, true) do
      assert Game.create!(host: hosts(:one), player_limit: 4).waiting?
    end
  end

  # ===========================================================================
  # Starting the game
  # ===========================================================================

  test "advance_step! starts the game: first round, first question, in_progress" do
    rounds = build_rounds(@game, [ 3, 3 ])

    assert_equal true, advance!

    @game.reload
    assert @game.in_progress?
    assert_equal rounds.first, @game.current_round
    assert_equal rounds.first.questions.order(:position).first, @game.current_question
    assert_not_nil @game.question_started_at
  end

  test "starting the game stamps shown_at on the first question only" do
    rounds = build_rounds(@game, [ 3 ])
    advance!

    questions = rounds.first.questions.order(:position)
    assert_not_nil questions.first.reload.shown_at
    assert_nil questions.second.reload.shown_at
    assert_nil questions.third.reload.shown_at
  end

  test "advance_step! returns false when the game has no rounds" do
    assert_equal false, advance!
    assert @game.reload.waiting?
  end

  test "advance_step! returns false when the first round has no questions" do
    @game.rounds.create!(title: "Empty round", position: 1)

    assert_equal false, advance!
    assert @game.reload.waiting?
  end

  test "game with a dangling current_round (fixture one) still starts cleanly" do
    game = games(:one)
    game.update_columns(current_round_id: nil)
    build_rounds(game, [ 2 ])

    assert_equal true, advance!(game)
    assert game.reload.in_progress?
    assert_not_nil game.current_round
  end

  # ===========================================================================
  # Questions within a round
  # ===========================================================================

  test "advance moves through the first three questions without a leaderboard" do
    build_rounds(@game, [ 10 ])
    advance! # start -> Q1

    statuses = []
    3.times do
      advance!
      statuses << @game.status
    end

    assert_equal %w[in_progress in_progress in_progress], statuses
    assert_equal 4, @game.questions_shown_count
  end

  test "each advanced question gets shown_at and question_started_at refreshed" do
    rounds = build_rounds(@game, [ 3 ])
    advance!
    first_started_at = @game.reload.question_started_at

    travel 5.seconds do
      advance!
    end

    @game.reload
    assert_operator @game.question_started_at, :>, first_started_at
    assert_not_nil @game.current_question.shown_at
    assert_equal rounds.first.questions.order(:position).second, @game.current_question
  end

  test "shown_at is not overwritten once set" do
    rounds = build_rounds(@game, [ 3 ])
    advance!
    q1 = rounds.first.questions.order(:position).first
    original = q1.reload.shown_at

    travel 1.minute do
      @game.send(:transition_to!, round: rounds.first, question: q1, status: :in_progress)
    end

    assert_equal original.to_i, q1.reload.shown_at.to_i
  end

  # ===========================================================================
  # Leaderboard every 4 questions
  # ===========================================================================

  test "leaderboard shows after the 4th question" do
    build_rounds(@game, [ 10 ])
    advance_to_question!(4)

    assert_equal true, advance!
    assert @game.reload.leaderboard?
  end

  test "leaderboard service is called with game, round and question" do
    rounds = build_rounds(@game, [ 10 ])
    advance_to_question!(4)
    q4 = @game.reload.current_question

    advance!

    assert_equal 1, @leaderboard_calls.size
    call = @leaderboard_calls.first
    assert_equal @game, call[:game]
    assert_equal rounds.first, call[:current_round]
    assert_equal q4, call[:current_question]
  end

  test "leaderboard keeps current_question so the host can continue" do
    build_rounds(@game, [ 10 ])
    advance_to_question!(4)
    q4 = @game.reload.current_question

    advance!

    assert_equal q4, @game.reload.current_question
  end

  test "advancing from the leaderboard returns to in_progress on question 5" do
    rounds = build_rounds(@game, [ 10 ])
    advance_to_question!(4)
    advance! # -> leaderboard

    assert_equal true, advance!

    @game.reload
    assert @game.in_progress?
    assert_equal rounds.first.questions.order(:position).fifth, @game.current_question
  end

  test "second leaderboard shows after the 8th question" do
    build_rounds(@game, [ 10 ])
    advance_to_question!(8)

    advance!

    assert @game.reload.leaderboard?
    assert_equal 2 - 1, @leaderboard_calls.size - 1 # sanity: only the 8th triggered another call (1 from Q4 + 1 from Q8)
  end

  test "no third leaderboard in a 10-question round: Q10 goes to round_summary" do
    build_rounds(@game, [ 10 ])
    advance_to_question!(10)

    advance!

    assert @game.reload.round_summary?
  end

  # ===========================================================================
  # should_show_leaderboard? / questions_shown_count (public API)
  # ===========================================================================

  test "questions_shown_count is zero without a current round" do
    assert_equal 0, @game.questions_shown_count
  end

  test "questions_shown_count counts only the current round" do
    rounds = build_rounds(@game, [ 3, 3 ])
    rounds.first.questions.update_all(shown_at: Time.current)
    @game.update!(current_round: rounds.second)

    assert_equal 0, @game.questions_shown_count
  end

  test "should_show_leaderboard? is true only on multiples of the interval" do
    rounds = build_rounds(@game, [ 10 ])
    @game.update!(current_round: rounds.first)
    questions = rounds.first.questions.order(:position).to_a

    expectations = { 0 => false, 1 => false, 2 => false, 3 => false,
                     4 => true, 5 => false, 7 => false, 8 => true, 9 => false }

    expectations.each do |shown, expected|
      rounds.first.questions.update_all(shown_at: nil)
      questions.first(shown).each { |q| q.update!(shown_at: Time.current) }
      @game.update!(current_question: questions[[ shown - 1, 0 ].max])

      assert_equal expected, @game.should_show_leaderboard?, "expected #{expected} after #{shown} shown"
    end
  end

  test "should_show_leaderboard? is false when the 4th question is the last of the round" do
    rounds = build_rounds(@game, [ 4 ])
    @game.update!(current_round: rounds.first, current_question: rounds.first.questions.order(:position).last)
    rounds.first.questions.update_all(shown_at: Time.current)

    assert_not @game.should_show_leaderboard?
  end

  test "LEADERBOARD_QUESTION_INTERVAL is 4" do
    assert_equal 4, Game::LEADERBOARD_QUESTION_INTERVAL
  end

  # ===========================================================================
  # Round summary
  # ===========================================================================

  test "after the last question of a round the game enters round_summary and stops there" do
    rounds = build_rounds(@game, [ 4, 4 ])
    advance_to_question!(4)

    assert_equal true, advance!

    @game.reload
    assert @game.round_summary?
    assert_equal rounds.first, @game.current_round, "must still be on round 1 until the host advances"
  end

  test "round_summary is persisted across requests (not overwritten in the same call)" do
    build_rounds(@game, [ 4, 4 ])
    advance_to_question!(4)
    advance!

    assert_equal "round_summary", Game.find(@game.id).status
  end

  test "entering round_summary shows the leaderboard and runs RoundTransitionService once" do
    build_rounds(@game, [ 4, 4 ])
    advance_to_question!(4)

    advance!

    assert_equal 1, @leaderboard_calls.size
    assert_equal 1, @transition_calls.size
    assert_equal @game, @transition_calls.first
  end

  test "round of exactly 4 questions skips the mid-round leaderboard" do
    build_rounds(@game, [ 4 ])
    advance_to_question!(4)

    advance!

    assert @game.reload.round_summary?
    assert_equal 1, @leaderboard_calls.size # the summary leaderboard only
  end

  test "round of 8 questions: Q8 goes to round_summary, not leaderboard then summary" do
    build_rounds(@game, [ 8 ])
    advance_to_question!(8)

    advance!

    assert @game.reload.round_summary?
  end

  test "advancing from round_summary starts the next round at its first question" do
    rounds = build_rounds(@game, [ 4, 4 ])
    advance_to_question!(4)
    advance! # -> round_summary

    assert_equal true, advance!

    @game.reload
    assert @game.in_progress?
    assert_equal rounds.second, @game.current_round
    assert_equal rounds.second.questions.order(:position).first, @game.current_question
    assert_not_nil rounds.second.questions.order(:position).first.reload.shown_at
  end

  test "leaderboard counter restarts in the new round" do
    build_rounds(@game, [ 4, 10 ])
    advance_to_question!(4)
    advance! # summary
    advance! # round 2 Q1

    assert_equal 1, @game.reload.questions_shown_count

    3.times { advance! } # Q2..Q4
    assert @game.reload.in_progress?
    advance!             # after Q4 of round 2
    assert @game.reload.leaderboard?
  end

  # ===========================================================================
  # Completion
  # ===========================================================================

  test "advancing from the final round_summary completes the game" do
    build_rounds(@game, [ 4 ])
    advance_to_question!(4)
    advance! # summary

    assert_equal true, advance!

    @game.reload
    assert @game.completed?
    assert_nil @game.current_question
    assert_nil @game.question_started_at
  end

  test "advance_step! returns false once completed and changes nothing" do
    build_rounds(@game, [ 4 ])
    advance_to_question!(4)
    advance!
    advance!
    assert @game.reload.completed?
    attrs = @game.attributes

    assert_equal false, advance!
    assert_equal attrs, @game.reload.attributes
  end

  # ===========================================================================
  # Full end-to-end cadence
  # ===========================================================================

  test "full game: leaderboard every 4 questions, summary at round end, completed at the end" do
    build_rounds(@game, [ 10, 10, 10 ])

    statuses = [ @game.status ]
    statuses << @game.status while advance!

    round = %w[in_progress] * 4 + %w[leaderboard] +
            %w[in_progress] * 4 + %w[leaderboard] +
            %w[in_progress] * 2 + %w[round_summary]

    assert_equal %w[waiting] + round * 3 + %w[completed], statuses
  end

  test "full game with uneven rounds (3, 4, 9)" do
    build_rounds(@game, [ 3, 4, 9 ])

    statuses = [ @game.status ]
    statuses << @game.status while advance!

    round1 = %w[in_progress] * 3 + %w[round_summary]
    round2 = %w[in_progress] * 4 + %w[round_summary]
    round3 = %w[in_progress] * 4 + %w[leaderboard] +
             %w[in_progress] * 4 + %w[leaderboard] +
             %w[in_progress] + %w[round_summary]

    assert_equal %w[waiting] + round1 + round2 + round3 + %w[completed], statuses
  end

  test "full game summary leaderboard count: one per leaderboard plus one per round" do
    build_rounds(@game, [ 10, 10 ])
    advance! while @game.reload.status != "completed"

    # 2 mid-round leaderboards per round + 1 summary per round = 6
    assert_equal 6, @leaderboard_calls.size
    assert_equal 2, @transition_calls.size
  end

  test "every question is shown exactly once, in position order" do
    rounds = build_rounds(@game, [ 5, 5 ])
    shown_order = []

    advance!
    shown_order << @game.reload.current_question.id
    while advance!
      q = @game.reload.current_question
      shown_order << q.id if q && shown_order.last != q.id
    end

    expected = rounds.flat_map { |r| r.questions.order(:position).pluck(:id) }
    assert_equal expected, shown_order
  end

  # ===========================================================================
  # Ordering edge cases
  # ===========================================================================

  test "rounds and questions with nil position fall back to id order" do
    r1 = @game.rounds.create!(title: "A", position: nil)
    r2 = @game.rounds.create!(title: "B", position: nil)
    q1 = r1.questions.create!(title: "A1", question_type: "true_false", position: nil)
    q2 = r1.questions.create!(title: "A2", question_type: "true_false", position: nil)
    r2.questions.create!(title: "B1", question_type: "true_false", position: nil)

    advance!
    assert_equal r1, @game.reload.current_round
    assert_equal q1, @game.current_question

    advance!
    assert_equal q2, @game.reload.current_question

    advance! # summary
    advance! # next round
    assert_equal r2, @game.reload.current_round
  end

  test "rounds are ordered by position even when created out of order" do
    late  = @game.rounds.create!(title: "Late",  position: 2)
    early = @game.rounds.create!(title: "Early", position: 1)
    early.questions.create!(title: "E1", question_type: "true_false", position: 1)
    late.questions.create!(title: "L1", question_type: "true_false", position: 1)

    advance!

    assert_equal early, @game.reload.current_round
  end

  # ===========================================================================
  # Unhandled / odd states
  # ===========================================================================

  test "advance_step! returns false for question_review (not handled)" do
    build_rounds(@game, [ 4 ])
    advance!
    @game.update!(status: :question_review)

    assert_equal false, advance!
    assert @game.reload.question_review?
  end

  test "status enum exposes all expected states" do
    assert_equal %w[waiting in_progress question_review leaderboard round_summary completed].sort,
                 Game.statuses.keys.sort
  end

  test "with_lock reloads stale instances so two hosts cannot double-advance" do
    build_rounds(@game, [ 10 ])
    advance!

    stale = Game.find(@game.id)
    advance!       # Q1 -> Q2 through @game
    stale.advance_step! # stale instance must see Q2 and move to Q3, not repeat Q2

    q_positions = @game.reload.current_question.position
    assert_equal 3, q_positions
  end

  # ===========================================================================
  # RoundTransitionService (uses the player fixtures)
  # ===========================================================================

  test "RoundTransitionService sets round_summary and clears the current question" do
    game, round = game_one_with_round
    stub_round_results do
      RoundTransitionService.call(game)
    end

    game.reload
    assert game.round_summary?
    assert_nil game.current_question
    assert_nil game.question_started_at
    assert_equal round, game.current_round
  end

  test "RoundTransitionService resets power-ups for active players" do
    game, _round = game_one_with_round
    players(:one).update_columns(power_ups: [], active_power_up: "double_points")

    stub_round_results { RoundTransitionService.call(game) }

    %i[one two three four].each do |key|
      player = players(key).reload
      assert_equal Player::POWER_UPS, player.power_ups, "#{key} power-ups should be reset"
      assert_nil player.active_power_up
      assert_nil player.active_power_up_question_id
    end
  end

  test "RoundTransitionService leaves eliminated players untouched" do
    game, _round = game_one_with_round
    players(:four).update_columns(eliminated: true, power_ups: [])

    stub_round_results { RoundTransitionService.call(game) }

    assert_equal [], players(:four).reload.power_ups
    assert_equal Player::POWER_UPS, players(:one).reload.power_ups
  end

  test "RoundTransitionService returns advancing and eliminated lists" do
    game, _round = game_one_with_round
    result = nil

    RoundResultsService.stub(:call, { advancing: [ 1, 2, 3 ], eliminated: [ 4 ] }) do
      result = RoundTransitionService.call(game)
    end

    assert_equal({ advancing: [ 1, 2, 3 ], eliminated: [ 4 ] }, result)
  end

  test "RoundTransitionService broadcasts round_summary to the game room" do
    game, round = game_one_with_round

    assert_broadcast_on("game_room_#{game.game_code}",
                        { event: "round_summary", game_id: game.id, round_id: round.id }) do
      stub_round_results { RoundTransitionService.call(game) }
    end
  end

  test "RoundTransitionService rolls back everything if RoundResultsService raises" do
    game, _round = game_one_with_round
    players(:one).update_columns(power_ups: [])

    boom = ->(**) { raise "scoring failed" }
    RoundResultsService.stub(:call, boom) do
      assert_raises(RuntimeError) { RoundTransitionService.call(game) }
    end

    assert_not game.reload.round_summary?
    assert_equal [], players(:one).reload.power_ups
  end

  private

  # --- helpers ---------------------------------------------------------------

  # Calls advance_step! with both services stubbed. RoundTransitionService is stubbed with
  # a lambda that mimics the real side effect (status -> round_summary, question cleared).
  def advance!(game = @game)
    result = nil

    leaderboard = ->(**kwargs) { @leaderboard_calls << kwargs; true }
    transition = lambda do |g|
      @transition_calls << g
      g.update!(status: :round_summary, current_question: nil, question_started_at: nil)
      { advancing: [], eliminated: [] }
    end

    DisplayLeaderboardService.stub(:call, leaderboard) do
      RoundTransitionService.stub(:call, transition) do
        result = game.advance_step!
      end
    end

    result
  end

  # Starts the game then advances until the given 1-based question is current (in_progress).
  def advance_to_question!(number)
    advance! # waiting -> Q1
    until @game.reload.questions_shown_count == number && @game.in_progress?
      advance!
      raise "never reached question #{number}" if @game.completed?
    end
  end

  # sizes: array of question counts, one entry per round
  def build_rounds(game, sizes)
    sizes.each_with_index.map do |count, r_index|
      round = game.rounds.create!(title: "Round #{r_index + 1}", position: r_index + 1)
      count.times do |q_index|
        round.questions.create!(
          title: "R#{r_index + 1} Q#{q_index + 1}",
          question_type: "true_false",
          position: q_index + 1
        )
      end
      round
    end
  end

  # games(:one) owns the four player fixtures
  def game_one_with_round
    game = games(:one)
    round = game.rounds.create!(title: "Round 1", position: 1)
    question = round.questions.create!(title: "Q1", question_type: "true_false", position: 1)
    game.update!(status: :in_progress, current_round: round, current_question: question)
    [ game, round ]
  end

  def stub_round_results(&block)
    RoundResultsService.stub(:call, { advancing: [], eliminated: [] }, &block)
  end
end
