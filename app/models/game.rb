class Game < ApplicationRecord
  before_validation :generate_game_code, on: :create

  belongs_to :host, class_name: "Host"
  belongs_to :current_round, class_name: "Round", optional: true
  belongs_to :current_question, class_name: "Question", optional: true

  has_many :players, dependent: :destroy
  has_many :rounds, -> { order(:position, :id) }, dependent: :destroy

  validates :game_code, presence: true, uniqueness: true
  validates :player_limit, numericality: { greater_than: 0 }

  after_create :populate_quiz_data

  enum :status, {
    waiting: "waiting",
    in_progress: "in_progress",
    completed: "completed"
  }, default: :waiting

  def advance_step!
    with_lock do
      return false if completed?

    global_rounds = Round.where(game_id: nil).ordered

      # 1. Starting the game from pending state
      if waiting? || current_round.nil?
        first_round = global_rounds.ordered.first
        return false unless first_round

        first_question = first_round.questions.first
        return false unless first_question

        transition_to!(round: first_round, question: first_question, status: :in_progress)
        return true
      end

      # 2. Check for the next question in the current round
      next_question = current_round.questions
                                   .where("position > ? OR (position = ? AND id > ?)",
                                          current_question.position,
                                          current_question.id)
                                   .order(:position, :id)
                                   .first

      if next_question.present?
        transition_to!(round: current_round, question: next_question)
        return true
      end

      # 3. Last question reached: Check for the next round
      next_round = global_rounds.where("position > ? OR (position = ? AND id > ?)",
                                current_round.position,
                                current_round.id)
                         .order(:position, :id)
                         .first

      if next_round.present?
        first_question_of_next_round = next_round.questions.first
        transition_to!(round: next_round, question: first_question_of_next_round)
        return true
      end

      # 4. No more rounds: Complete game
      update!(
        status: :completed,
        current_question: nil,
        question_started_at: nil
      )
      true
    end
  end

  private

  def transition_to!(round:, question:, status: self.status)
    update!(
      status: status,
      current_round: round,
      current_question: question,
      question_started_at: Time.current
    )
  end

  def generate_game_code
    self.game_code = SecureRandom.hex(3).upcase
  end

  def populate_quiz_data
        QuizPopulator.call(self)
  end
end
