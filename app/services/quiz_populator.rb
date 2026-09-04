class QuizPopulator
  def self.call(game)
    # 1. Fetch template rounds with questions and options eagerly loaded (no N+1 queries)
    rounds_from_quiz_data = Round.where(game_id: nil)
                           .includes(questions: :options)
                           .order(:position, :id)

    raise ActiveRecord::RecordNotFound, "No seed template rounds found. Run rails db:seed." if rounds_from_quiz_data.empty?

    ActiveRecord::Base.transaction do
      rounds_from_quiz_data.each do |tpl_round|
        # 2. Clone round and link to this specific game
        new_round_in_database = tpl_round.dup
        new_round_in_database.game = game
        new_round_in_database.save!

        tpl_round.questions.each do |tpl_question|
          # 3. Clone question under the new round
          new_question_in_database = tpl_question.dup
          new_question_in_database.round = new_round_in_database
          new_question_in_database.correct_answer_ids = [] # Temporarily reset until options are cloned
          new_question_in_database.save!

          old_to_new_option_ids = {}

          # 4. Clone each option under the new question
          tpl_question.options.each do |tpl_option|
            new_option_in_database = tpl_option.dup
            new_option_in_database.question = new_question_in_database
            new_option_in_database.save!

            old_to_new_option_ids[tpl_option.id] = new_option_in_database.id
          end

          # 5. Map the original correct_answer_ids to the newly cloned option IDs
          new_correct_ids = (tpl_question.correct_answer_ids || []).map do |old_id|
            old_to_new_option_ids[old_id]
          end.compact

          new_question_in_database.update_columns(correct_answer_ids: new_correct_ids)
        end
      end
    end

    game.rounds.reload
  end
end
