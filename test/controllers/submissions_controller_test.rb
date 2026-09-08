require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = players(:one)
    @question = questions(:one)
    @game = @player.game

    @correct_option = @question.options.find do |option|
      @question.correct_answer_ids.include?(option.position)
    end

    @incorrect_option = @question.options.find do |option|
      !@question.correct_answer_ids.include?(option.position)
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
            option_id: @correct_option.id
          }
        }
    end

    assert_response :created

    submission = Submission.last

    assert_equal @player.id, submission.player_id
    assert_equal @question.id, submission.question_id
    assert_equal @question.round.id, submission.round_id
    assert_equal @correct_option.id, submission.option_id

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
            option_id: @incorrect_option.id
          }
        }
    end

    assert_response :created

    submission = Submission.last

    assert_equal @player.id, submission.player_id
    assert_equal @question.id, submission.question_id
    assert_equal @question.round.id, submission.round_id
    assert_equal @incorrect_option.id, submission.option_id

    assert_in_delta 4_000, submission.response_time_ms, 100
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
            option_id: @correct_option.id
          }
        }
    end

    assert_response :created

    submission = Submission.last

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
            option_id: @correct_option.id,
            response_time_ms: 1
          }
        }
    end

    assert_response :created

    submission = Submission.last

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
        option_id: @correct_option.id
      }
    }

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
        option_id: @incorrect_option.id
      }
    }

  assert_response :created

  response_body = JSON.parse(response.body)

  assert_equal false, response_body["correct"]
  assert_equal 0, response_body["points_awarded"]
  end
end
