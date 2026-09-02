require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = Host.create!(
      name: "Test Host",
      token: "host-token"
    )

    @game = @host.games.create!(
      game_code: "TEST123"
    )

    @player = @game.players.create!(
      username: "Alice",
      token: "player-token"
    )

    @round = @game.rounds.create!(
      title: "Round 1"
    )

    @question = @round.questions.create!(
      title: "What is the capital of France?",
      answer: "Paris"
    )
  end

  test "creates a submission for the authenticated player" do
    assert_difference("Submission.count", 1) do
      post submissions_url,
        params: {
          submission: {
            question_id: @question.id,
            round_id: @round.id,
            answer: "Paris",
            response_time_ms: 4200
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
    assert_equal "Paris", submission.answer
    assert_equal 4200, submission.response_time_ms
  end
end
