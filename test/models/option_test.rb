require "test_helper"
require "stringio"

class OptionTest < ActiveSupport::TestCase
  test "includes image_url when image is attached" do
      option = options(:one_correct)

      option.image.attach(
        io: StringIO.new("fake image data"),
        filename: "test-option.jpg",
        content_type: "image/jpeg"
      )

      ActiveStorage::Current.url_options = {
        host: "localhost",
        port: 3000
      }

      json = option.as_json

      assert json["image_url"].present?
    ensure
      ActiveStorage::Current.url_options = nil
  end

  test "returns nil image_url when no image is attached" do
    option = options(:one_correct)

    json = option.as_json

    assert_nil json["image_url"]
  end
end
