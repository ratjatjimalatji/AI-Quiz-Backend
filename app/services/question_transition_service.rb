class QuestionTransitionService
  def self.call(game)
    new(game).process
  end

  def initialize(game)
    @game = game
    @question = game.current_question
  end

  def process
    @game.update!(status: :question_review)

     ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
      event: "question_review",
      question_id: @question.id,
      correct_option_position: @question.correct_option_position
      }
    )
  end
end
