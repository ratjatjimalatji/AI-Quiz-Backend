class QuizPopulator
      QUIZ_DATA = YAML.load_file(Rails.root.join("db", "seeds", "quiz_data.yml")).freeze

      def self.call(game)
        ActiveRecord::Base.transaction do
          QUIZ_DATA["rounds"].each do |round_raw|
            # 1. Creates the round with the game"s newly generated ID
            round = game.rounds.create!(
              title: round_raw["title"]
            )

            round_raw["questions"].each do |q_raw|
              # 2. Creates the question under this round
              question = round.questions.create!(
                title: q_raw["title"],
                question_type: q_raw["question_type"]
              )

              # 3. Creates options and maps old YAML IDs to new DB IDs
              yaml_to_db_option_id = {}
              q_raw["options"].each do |opt_raw|
                option = question.options.create!(
                  text: opt_raw["text"],
                  position: opt_raw["position"]
                )
                yaml_to_db_option_id[opt_raw["id"]] = option.id
              end

              # 4. Updates correct_answer_ids with the new option IDs
              mapped_correct_ids = (q_raw["correct_answer_ids"] || []).map do |yaml_opt_id|
                yaml_to_db_option_id[yaml_opt_id]
              end.compact

              question.update!(correct_answer_ids: mapped_correct_ids)
            end
          end
        end
      end
end
