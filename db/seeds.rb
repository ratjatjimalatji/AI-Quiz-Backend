require 'yaml'

file_path = Rails.root.join('db', 'seeds', 'quiz_data.yml')
quiz_data = YAML.load_file(file_path)

puts "== Syncing Quiz Data from YAML (Source of Truth) =="

ActiveRecord::Base.transaction do
  processed_round_ids = []
  processed_question_ids = []
  processed_option_ids = []

  quiz_data['rounds'].each do |round_raw|
    round = Round.find_or_initialize_by(title: round_raw['title'])
    round.save!
    processed_round_ids << round.id

    round_raw['questions'].each do |q_raw|
      question = round.questions.find_or_initialize_by(title: q_raw['title'])
      question.question_type = q_raw['question_type']
      question.save!
      processed_question_ids << question.id

      yaml_to_db_option_id = {}

      q_raw['options'].each do |opt_raw|
        option = question.options.find_or_initialize_by(text: opt_raw['text'])
        option.position = opt_raw['position']
        option.save!

        yaml_to_db_option_id[opt_raw['id']] = option.id
        processed_option_ids << option.id
      end

      mapped_correct_ids = (q_raw['correct_answer_ids'] || []).map do |yaml_opt_id|
        yaml_to_db_option_id[yaml_opt_id]
      end.compact

      question.update!(correct_answer_ids: mapped_correct_ids)
    end
  end

  Option.where.not(id: processed_option_ids).destroy_all
  Question.where.not(id: processed_question_ids).destroy_all
  Round.where.not(id: processed_round_ids).destroy_all

  puts "== Sync Complete: #{Round.count} rounds, #{Question.count} questions, #{Option.count} options =="
end
