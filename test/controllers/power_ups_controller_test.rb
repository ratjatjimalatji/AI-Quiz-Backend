require "test_helper"

class PowerUpsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @player = players(:one)
    @player.update!(
      token: "player-one-powerup-token",
      score: 0,
      power_ups: %w[get_hundred_points double_points glitch_sabotage],
      eliminated: false,
      active_power_up: nil,
      active_power_up_question_id: nil
    )
    @victim = players(:two)
    @victim.update!(
      token: "player-two-powerup-token",
      score: 0,
      power_ups: %w[get_hundred_points double_points glitch_sabotage],
      eliminated: false
    )
    @game = @player.game
    @victim.update!(game: @game)
    @question = questions(:one)
    @question.round.update!(game: @game)

    @game.update!(
      current_question_id: @question.id,
      question_started_at: 2.seconds.ago,
      status: "in_progress"
    )

    @headers = { "Authorization" => "Bearer #{@player.token}" }
  end

  test "use get_hundred_points creates submission, increments score, and deducts inventory" do
    assert_difference("Submission.count", 1) do
      post power_ups_use_path,
        params: {
          power_up: {
            question_id: @question.id,
            power_name: "get_hundred_points"
          }
        },
        headers: @headers
    end

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "get_hundred_points", body["power_name"]
    assert_equal 100, body.dig("data", "points_awarded")
    assert body.dig("data", "submission").present?

    @player.reload
    assert_equal 100, @player.score
    assert_not_includes @player.power_ups, "get_hundred_points"

    submission = @player.submissions.find_by!(question: @question)
    assert_equal 100, submission.points_awarded
    assert_equal "get_hundred_points", submission.answer
  end

  test "use glitch_sabotage deducts inventory, broadcasts ActionCable event, and returns 200" do
    assert_broadcast_on("game_room_#{@game.game_code}", {
      event: "#{@player.username} used glitch sabotaged on #{@victim.username}",
      initiator_id: @player.id,
      initiator_name: @player.username,
      victim_id: @victim.id,
      victim_name: @victim.username,
      question_id: @question.id,
      glitch_duration_ms: 10_000
    }) do
      post power_ups_use_path,
        params: {
          power_up: {
            question_id: @question.id,
            power_name: "glitch_sabotage",
            victim_player_id: @victim.id
          }
        },
        headers: @headers
    end

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "glitch_sabotage", body["power_name"]
    assert_equal @victim.id, body.dig("data", "victim_player_id")
    assert_equal 10_000, body.dig("data", "glitch_duration_ms")

    @player.reload
    assert_not_includes @player.power_ups, "glitch_sabotage"
  end

  test "use double_points activates deferred power-up and deducts inventory" do
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "double_points"
        }
      },
      headers: @headers

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "double_points", body["power_name"]
    assert_equal "double_points", body.dig("data", "active_power_up")

    @player.reload
    assert_equal "double_points", @player.active_power_up
    assert_equal @question.id, @player.active_power_up_question_id
    assert_not_includes @player.power_ups, "double_points"
  end

  test "use power-up fails with 401 when unauthorized" do
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "get_hundred_points"
        }
      }

    assert_response :unauthorized
  end

  test "use power-up fails with 400 when power-up name is invalid" do
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "unknown_power"
        }
      },
      headers: @headers

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_match(/Invalid power-up/, body["error"])
  end

  test "use get_hundred_points fails with 422 when not in inventory" do
    @player.update!(power_ups: %w[double_points])

    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "get_hundred_points"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "Power-up not available", body["error"]
  end

  test "use glitch_sabotage fails with 422 when targeting yourself" do
    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "glitch_sabotage",
          victim_player_id: @player.id
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "Cannot sabotage yourself", body["error"]
  end

  test "use glitch_sabotage fails with 422 when victim is eliminated" do
    @victim.update!(eliminated: true)

    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "glitch_sabotage",
          victim_player_id: @victim.id
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "Target player not found or eliminated", body["error"]
  end

  test "use power-up fails with 422 when game is not in progress" do
    @game.update!(status: "waiting")

    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "get_hundred_points"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
  end

  test "use get_hundred_points fails with 422 when question already answered" do
    @player.submissions.create!(
      question: @question,
      round: @question.round,
      answer: "1",
      response_time_ms: 1000,
      points_awarded: 50
    )

    post power_ups_use_path,
      params: {
        power_up: {
          question_id: @question.id,
          power_name: "get_hundred_points"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_equal "Question already answered", body["error"]
  end
end
