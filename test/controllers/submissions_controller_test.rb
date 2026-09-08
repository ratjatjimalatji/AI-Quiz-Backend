require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = players(:one)
    @question = questions(:one)

    @correct_option = @question.options.find do |option|
      @question.correct_answer_ids.include?(option.position)
    end

    @incorrect_option = @question.options.find do |option|
      !@question.correct_answer_ids.include?(option.position)
    end
  end

  test "creates a submission for a correct answer" do
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
    assert_equal 0, submission.response_time_ms
    assert_equal 100, submission.points_awarded
  end

  test "creates a submission with zero points for an incorrect answer" do
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
    assert_equal 0, submission.response_time_ms
    assert_equal 0, submission.points_awarded
  end

  test "awards points to the player for a correct answer" do
    starting_score = @player.score

    post submissions_path,
      params: {
        submission: {
          question_id: @question.id,
          option_id: @correct_option.id
        }
      }

    assert_response :created
    assert_equal starting_score + 100, @player.reload.score
  end

  test "does not accept response time from the request" do
    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            option_id: @correct_option.id,
            response_time_ms: 10_000
          }
        }
    end

    assert_response :created

    submission = Submission.last

    assert_equal 0, submission.response_time_ms
    assert_equal 100, submission.points_awarded
  end
end
