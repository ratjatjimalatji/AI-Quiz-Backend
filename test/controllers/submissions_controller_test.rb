require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
include ActionCable::TestHelper
  setup do
    @player = players(:one)
    @player.update!(token: "player-one-token", score: 0)
    @question = questions(:one)
    @game = @player.game
    @headers = { "Authorization" => "Bearer #{@player.token}" }

    @correct_option = @question.options.find do |option|
      @question.correct_option_positions.include?(option.position)
    end

    @incorrect_option = @question.options.find do |option|
      !@question.correct_option_positions.include?(option.position)
    end
  end

  test "creates a submission for a correct answer" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 4.seconds.ago
    )

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            answer: @correct_option.position
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: @question)

    assert_equal @player.id, submission.player_id
    assert_equal @question.id, submission.question_id
    assert_equal @question.round.id, submission.round_id
    assert_equal @correct_option.position, submission.answer.to_i

    assert_in_delta 4_000, submission.response_time_ms, 100
    assert_equal 100, submission.points_awarded
  end

  test "creates a submission with zero points for an incorrect answer" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 4.seconds.ago
    )

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            answer: @incorrect_option.position
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: @question)

    assert_equal @player.id, submission.player_id
    assert_equal @question.id, submission.question_id
    assert_equal @question.round.id, submission.round_id
    assert_equal @incorrect_option.position, submission.answer.to_i

    assert_in_delta 4_000, submission.response_time_ms, 200
    assert_equal 0, submission.points_awarded
  end

  test "awards fewer points when a correct answer takes longer than five seconds" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 7.seconds.ago
    )

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            answer: @correct_option.position
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: @question)

    assert_equal @correct_option.position, submission.answer.to_i
    assert_in_delta 7_000, submission.response_time_ms, 100
    assert_equal 98, submission.points_awarded
  end

  test "does not accept response time from the request" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 7.seconds.ago
    )

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            answer: @correct_option.position,
            response_time_ms: 1
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: @question)

    assert_in_delta 7_000, submission.response_time_ms, 100
    assert_equal 98, submission.points_awarded
  end

  test "returns correctness and points awarded for a correct answer" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 4.seconds.ago
    )

    post submissions_path,
      params: {
        submission: {
          question_id: @question.id,
          answer: @correct_option.position
        }
      },
      headers: @headers

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal true, response_body["correct"]
    assert_equal 100, response_body["points_awarded"]
  end

  test "returns correctness and zero points for an incorrect answer" do
    @game.update!(
      current_question_id: @question.id,
      question_started_at: 4.seconds.ago
    )

    post submissions_path,
      params: {
        submission: {
          question_id: @question.id,
          answer: @incorrect_option.position
        }
      },
      headers: @headers

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal false, response_body["correct"]
    assert_equal 0, response_body["points_awarded"]
  end

  test "creates a submission for a correct sequence answer" do
  question = questions(:sequence_question)

  @game.update!(
    current_question_id: question.id,
    question_started_at: 4.seconds.ago
  )

  correct_sequence = question.correct_option_positions

  assert_difference("Submission.count", 1) do
    post submissions_path,
      params: {
        submission: {
          question_id: question.id,
          answer: correct_sequence
        }
      },
      headers: @headers
  end

  assert_response :created

  submission = @player.submissions.find_by!(question: question)

  assert_equal @player.id, submission.player_id
  assert_equal question.id, submission.question_id
  assert_equal question.round.id, submission.round_id
  assert_equal correct_sequence, submission.answer.map(&:to_i)

  assert_in_delta 4_000, submission.response_time_ms, 200
  assert_equal 100, submission.points_awarded

  response_body = JSON.parse(response.body)

  assert_equal true, response_body["correct"]
  assert_equal 100, response_body["points_awarded"]
  end

  test "creates a submission with zero points for an incorrect sequence answer" do
    question = questions(:sequence_question)

    @game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago
    )

    incorrect_sequence = question.correct_option_positions.reverse

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: question.id,
            answer: incorrect_sequence
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: question)

    assert_equal @player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal incorrect_sequence, submission.answer.map(&:to_i)

    assert_in_delta 4_000, submission.response_time_ms, 200
    assert_equal 0, submission.points_awarded

    response_body = JSON.parse(response.body)

    assert_equal false, response_body["correct"]
    assert_equal 0, response_body["points_awarded"]
  end

  test "creates a submission for a correct fill in the blank answer" do
    question = questions(:fill_in_the_blank_question)

    @game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago
    )

    correct_answer = question.options.first.text

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: question.id,
            answer: correct_answer
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: question)

    assert_equal @player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal correct_answer, submission.answer

    assert_in_delta 4_000, submission.response_time_ms, 100
    assert_equal 100, submission.points_awarded

    response_body = JSON.parse(response.body)

    assert_equal true, response_body["correct"]
    assert_equal 100, response_body["points_awarded"]
  end

  test "accepts a fill in the blank answer regardless of case and surrounding whitespace" do
    question = questions(:fill_in_the_blank_question)

    @game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago
    )

    correct_answer = question.options.first.text

    post submissions_path,
      params: {
        submission: {
          question_id: question.id,
          answer: "  #{correct_answer.downcase}  "
        }
        },
        headers: @headers

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal true, response_body["correct"]
    assert_equal 100, response_body["points_awarded"]
  end

  test "creates a submission with zero points for an incorrect fill in the blank answer" do
    question = questions(:fill_in_the_blank_question)

    @game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago
    )

    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: question.id,
            answer: "Definitely not the answer"
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = @player.submissions.find_by!(question: question)

    assert_equal @player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal "Definitely not the answer", submission.answer

    assert_in_delta 4_000, submission.response_time_ms, 100
    assert_equal 0, submission.points_awarded

    response_body = JSON.parse(response.body)

    assert_equal false, response_body["correct"]
    assert_equal 0, response_body["points_awarded"]
  end

  test "activates double points and awards 2x points for a correct answer" do
  freeze_time do
    question = questions(:fill_in_the_blank_question)
    game = question.round.game
    player = players(:one)

    game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago,
      status: "in_progress"
    )

    @player.update!(
    score: 0,
    power_ups: %w[double_points get_hundred_points],
    active_power_up: nil,
    active_power_up_question_id: nil
  )

    # 1. Activate double_points power-up
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: question.id,
          power_name: "double_points"
        }
      },
      headers: @headers

    assert_response :ok
    player.reload
    assert_equal "double_points", player.active_power_up
    assert_equal question.id, player.active_power_up_question_id
    assert_not_includes player.power_ups, "double_points"

    correct_answer = question.options.find_by!(position: question.correct_option_positions.first).text

    # 2. Submit correct answer; base score is 100, doubled to 200
    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: question.id,
            answer: correct_answer
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = player.submissions.find_by!(question: question)

    assert_equal player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal correct_answer, submission.answer

    assert_in_delta 4_000, submission.response_time_ms, 200
    assert_equal 200, submission.points_awarded

    response_body = JSON.parse(response.body)
    assert_equal true, response_body["correct"]
    assert_equal 200, response_body["points_awarded"]

    # 3. Verify player score incremented and active power-up was consumed
    player.reload
    assert_equal 200, player.score
    assert_nil player.active_power_up
    assert_nil player.active_power_up_question_id
  end
end

  test "activates double points and awards zero points for an incorrect answer" do
    question = questions(:sequence_question)
    game = question.round.game
    player = players(:one)

    game.update!(
      current_question_id: question.id,
      question_started_at: 4.seconds.ago,
      status: "in_progress"
    )

    @player.update!(
    score: 0,
    power_ups: %w[double_points get_hundred_points],
    active_power_up: nil,
    active_power_up_question_id: nil
    )

    # 1. Activate double_points power-up
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: question.id,
          power_name: "double_points"
        }
      },
      headers: @headers

    assert_response :ok
    player.reload
    assert_equal "double_points", player.active_power_up
    assert_equal question.id, player.active_power_up_question_id
    assert_not_includes player.power_ups, "double_points"

    incorrect_sequence = question.correct_option_positions.reverse

    # 2. Submit incorrect answer; 0 multiplied by 2 remains 0
    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: question.id,
            answer: incorrect_sequence
          }
        },
        headers: @headers
    end

    assert_response :created

    submission = player.submissions.find_by!(question: question)

    assert_equal player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal incorrect_sequence, submission.answer.map(&:to_i)

    assert_in_delta 4_000, submission.response_time_ms, 200
    assert_equal 0, submission.points_awarded

    response_body = JSON.parse(response.body)
    assert_equal false, response_body["correct"]
    assert_equal 0, response_body["points_awarded"]

    # 3. Verify power-up is still consumed and score stays at 0
    player.reload
    assert_equal 0, player.score
    assert_nil player.active_power_up
    assert_nil player.active_power_up_question_id
  end

  test "auto_100_points immediately creates a submission and awards 100 points without an answer" do
    question = questions(:sequence_question)
    game = question.round.game
    player = players(:one)

    game.update!(
      current_question_id: question.id,
      question_started_at: 8.seconds.ago, # Beyond free time, but score must still be 100
      status: "in_progress"
    )

    player.update!(
    game: game,
    score: 0,
    power_ups: %w[get_hundred_points double_points],
    active_power_up: nil,
    active_power_up_question_id: nil
    )

    # Trigger auto_100_points: creates submission immediately
    assert_difference("Submission.count", 1) do
      post power_ups_use_path,
        params: {
          power_up: {
            question_id: question.id,
            power_name: "get_hundred_points"
          }
        },
        headers: @headers
    puts "RESPONSE STATUS: #{response.status}"
    puts "RESPONSE BODY: #{response.body}"
    end
    assert_response :ok

    submission = player.submissions.find_by!(question: question)

    assert_equal player.id, submission.player_id
    assert_equal question.id, submission.question_id
    assert_equal question.round.id, submission.round_id
    assert_equal "get_hundred_points", submission.answer

    assert_in_delta 8_000, submission.response_time_ms, 500
    assert_equal 100, submission.points_awarded

    response_body = JSON.parse(response.body)
    assert_equal true, response_body["success"]
    assert_equal "get_hundred_points", response_body["power_name"]
    assert_equal 100, response_body.dig("data", "points_awarded")

    player.reload
    assert_equal 100, player.score
    assert_not_includes player.power_ups, "get_hundred_points"
    assert_nil player.active_power_up
    assert_nil player.active_power_up_question_id
  end
end
