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

    # 3. Broadcast answers and response breakdown to clients
    GameChannel.broadcast_to(@game, {
      event: "question_review",
      question_id: @question.id,
      correct_answer_ids: @question.correct_answer_ids
    })
  end
end
