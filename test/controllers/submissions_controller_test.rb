require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = players(:one)
    @player.update!(token: "player-one-token")
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

  assert_in_delta 4_000, submission.response_time_ms, 100
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

  assert_in_delta 4_000, submission.response_time_ms, 100
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
end
