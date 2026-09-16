require "test_helper"

class HostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = Host.create!(name: "Host 1")
    @game = Game.create!(
      host: @host
    )
  end

  test "should get index" do
    host = hosts(:one)
    get hosts_url,
    headers: {
      "Authorization" => "Bearer #{host.token}"
    }

    puts response.body

    assert_response :success
  end

  test "should create host" do
    post hosts_url, params: {
      host: {
        name: "Quiz Master",
        password: "password123"
      }
    }

    assert_response :created
  end



  test "allows the host to rejoin their game when token is valid and game is active" do
    post rejoin_hosts_path, params: {
      game_code: @game.game_code
    },
     headers: {
       "Authorization" => "Bearer #{@host.token}"
     }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_equal @host.id, json["host"]["id"]
    assert_equal @game.game_code, json["game"]["game_code"]
  end

  test "rejects rejoin when game has completed" do
    @game.update!(status: "completed")

    post rejoin_hosts_path, params: {
      game_code: @game.game_code
    },
     headers: {
       "Authorization" => "Bearer #{@host.token}"
     }

    assert_response :gone
  end

  test "rejects rejoin when host token is missing or invalid" do
    post rejoin_hosts_path, params: {
      game_code: @game.game_code
    },
     headers: {
       "Authorization" =>  "Bearer invalid-token"
     }

    assert_response :unauthorized
  end
end
