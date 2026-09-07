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

    # 1. Start game if waiting or current_round not set
    if waiting? || current_round.nil?
      first_round = rounds.order(Arel.sql("COALESCE(position, 0) ASC"), :id).first
      return false unless first_round

      first_question = first_round.questions.order(Arel.sql("COALESCE(position, 0) ASC"), :id).first
      return false unless first_question

      transition_to!(round: first_round, question: first_question, status: :in_progress)
      return true
    end

    # 2. Find next question in current round
    current_question_position = current_question.position || 0
    current_question_id  = current_question.id

    next_question = current_round.questions
      .where(
        "COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)",
        current_question_position, current_question_position, current_question_id
      )
      .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
      .first

    if next_question.present?
      transition_to!(round: current_round, question: next_question)
      return true
    end

    # 3. Last question reached: Find next round
    current_round_position = current_round.position || 0
    current_round_id  = current_round.id

    next_round = rounds
      .where(
        "COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)",
        current_round_position, current_round_position, current_round_id
      )
      .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
      .first
    # 3. Last question reached: Find next round
    current_round_position = current_round.position || 0
    current_round_id  = current_round.id

    next_round = rounds
      .where(
        "COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)",
        current_round_position, current_round_position, current_round_id
      )
      .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
      .first

    if next_round.present?
      first_question_of_next_round = next_round.questions
                                               .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
                                               .first
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
