class QuizPopulator
  DEFAULT_PATH = Rails.root.join("db/seeds/quiz_data.yml")

  def self.call(game, path: DEFAULT_PATH)
    new(game, path).call
  end

  def initialize(game, path)
    @game = game
    @data = YAML.load_file(path)
  end

  def call
    Game.transaction do
      @data.fetch("rounds").each_with_index do |round_data, r_idx|
        round = @game.rounds.create!(
          title: round_data["title"],
          position: round_data["position"] || r_idx + 1
        )

        round_data.fetch("questions").each_with_index do |q_data, q_idx|
          question = round.questions.create!(
            title: q_data["title"],
            question_type: q_data["question_type"],
            position: q_data["position"] || q_idx + 1
          )

          correct_ids = []
          q_data.fetch("options").each_with_index do |o_data, o_idx|
            option = question.options.create!(
              text: o_data["text"],
              position: o_data["position"] || o_idx + 1
            )
            correct_ids << option.id if o_data["correct"]
          end

          question.update!(correct_answer_ids: correct_ids)
        end
      end
    end
  end
end
