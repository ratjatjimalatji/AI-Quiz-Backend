require "test_helper"
require "stringio"

class QuestionTest < ActiveSupport::TestCase
  test "includes option image_url in json" do
    question = questions(:one)
    option = question.options.first

    option.image.attach(
      io: StringIO.new("fake image data"),
      filename: "test-option.jpg",
      content_type: "image/jpeg"
    )

    ActiveStorage::Current.url_options = {
      host: "localhost",
      port: 3000
    }

    json = question.as_json

    pp json

    json_option = json["options"].find do |item|
      item["id"] == option.id
    end

    assert json_option["image_url"].present?
  ensure
    ActiveStorage::Current.url_options = nil
  end
end
