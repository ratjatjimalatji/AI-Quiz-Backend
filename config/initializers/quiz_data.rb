# config/initializers/quiz_data.rb
raw_config = YAML.load_file(Rails.root.join("db", "seeds", "quiz_data.yml"))
QUIZ_DATA = raw_config.deep_symbolize_keys.freeze
