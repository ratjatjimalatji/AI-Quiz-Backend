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

          template_correct_positions = q_data.fetch("correct_answer_ids", [])
          id_map = {}

          q_data.fetch("options").each_with_index do |o_data, o_idx|
            position = o_data["position"] || (o_idx + 1)
            option = question.options.create!(
              text: o_data["text"],
              position: position
            )
            id_map[position] = option.id
          end

          new_correct_ids = template_correct_positions.map do |pos|
            id_map.fetch(pos) do
              raise "QuizPopulator: question #{q_data['id'].inspect} " \
                    "(#{q_data['title'].inspect}) has correct_answer_ids " \
                    "referencing position #{pos.inspect}, but its options " \
                    "have positions #{id_map.keys.inspect}"
            end
          end

          question.update!(correct_answer_ids: new_correct_ids)
        end
      end
    end
  end
end
