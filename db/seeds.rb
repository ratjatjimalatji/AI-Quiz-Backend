quiz_data = YAML.load_file(Rails.root.join("db", "seeds", "quiz_data.yml"))

ActiveRecord::Base.transaction do
  quiz_data["rounds"].each_with_index do |round_raw, r_idx|
    round = Round.find_or_create_by!(game_id: nil, title: round_raw["title"]) do |r|
      r.position = round_raw["position"] || (r_idx + 1)
    end

    round_raw["questions"].each_with_index do |q_raw, q_idx|
      question = round.questions.find_or_create_by!(title: q_raw["title"]) do |q|
        q.question_type = q_raw["question_type"]
        q.position = q_raw["position"] || (q_idx + 1)
      end

      next if question.options.exists?

      yaml_to_db_option_id = {}
      q_raw["options"].each do |opt_raw|
        option = question.options.create!(text: opt_raw["text"], position: opt_raw["position"])
        yaml_to_db_option_id[opt_raw["id"]] = option.id
      end

      mapped_correct_ids = (q_raw["correct_answer_ids"] || []).map { |yid| yaml_to_db_option_id[yid] }.compact
      question.update!(correct_answer_ids: mapped_correct_ids)
    end
  end
end
