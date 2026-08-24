require "test_helper"

class HostsControllerTest < ActionDispatch::IntegrationTest
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
end
