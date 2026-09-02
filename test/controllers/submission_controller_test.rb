require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = Host.create!(name: "Test Host")
    @game = @host.games.create!(game_code: "TEST123")

    @player = @game.players.create!(
      username: "Alice",
      token: "player-token"
    )

    @round = @game.rounds.create!(title: "Round 1")

    @question = @round.questions.create!(
      title: "Anthropic was founded before OpenAI.",
      question_type: "true_false",
      correct_answer_ids: [ 1 ]
    )

    @correct_option = @question.options.create!(
      text: "True",
      position: 1
    )

    @incorrect_option = @question.options.create!(
      text: "False",
      position: 2
    )
  end

  test "creates a submission for a correct answer" do
    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            option_id: @correct_option.id,
            response_time_ms: 4_000
          }
        },
        headers: {
          "Authorization" => "Bearer #{@player.token}"
        }
    end

    assert_response :created

    submission = Submission.last

    assert_equal @player.id, submission.player_id
    assert_equal @question.id, submission.question_id
    assert_equal @round.id, submission.round_id
    assert_equal @correct_option.id, submission.option_id
    assert_equal 4_000, submission.response_time_ms
    assert_equal 100, submission.points_awarded

    @player.reload
    assert_equal 100, @player.score
  end

  test "creates a submission with zero points for an incorrect answer" do
    assert_difference("Submission.count", 1) do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            option_id: @incorrect_option.id,
            response_time_ms: 4_000
          }
        },
        headers: {
          "Authorization" => "Bearer #{@player.token}"
        }
    end

    assert_response :created

    submission = Submission.last

    assert_equal @incorrect_option.id, submission.option_id
    assert_equal 4_000, submission.response_time_ms
    assert_equal 0, submission.points_awarded

    @player.reload
    assert_equal 0, @player.score
  end

  test "awards fewer points when a correct answer takes longer than five seconds" do
    post submissions_path,
      params: {
        submission: {
          question_id: @question.id,
          option_id: @correct_option.id,
          response_time_ms: 7_000
        }
      },
      headers: {
        "Authorization" => "Bearer #{@player.token}"
      }

    assert_response :created

    submission = Submission.last

    # 5 seconds are free.
    # 2 additional seconds = 2 points deducted.
    assert_equal 98, submission.points_awarded

    @player.reload
    assert_equal 98, @player.score
  end

  test "rejects an unauthenticated player" do
    assert_no_difference("Submission.count") do
      post submissions_path,
        params: {
          submission: {
            question_id: @question.id,
            option_id: @correct_option.id,
            response_time_ms: 4_000
          }
        }
    end

    assert_response :unauthorized
  end
end
