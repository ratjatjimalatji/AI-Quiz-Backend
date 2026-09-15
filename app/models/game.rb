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
    question_review: "question_review",
    round_summary: "round_summary",
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

      # 2. Question transitions to review after all players have submitted their answers
      if in_progress?
        #   QuestionTransitionService.call(self)
        #   return true
        # end

        # # 3. If currently reviewing a question, decide next destination
        # if question_review?
        next_question = go_to_next_question(current_question)

        if next_question.present?
          # Next question in the current round
          transition_to!(round: current_round, question: next_question, status: :in_progress)
          return true
        end

        # No more questions in round; check for next round
        next_round = go_to_next_round(current_round)

        if next_round.present?
          RoundTransitionService.call(self)
          return true
        else
          complete_game!
          return true
        end
      end

      # 4. If on round summary, transition to the first question of the next round
      if round_summary?
        next_round = go_to_next_round(current_round)

        if next_round.present?
          first_q = next_round.questions.order(Arel.sql("COALESCE(position, 0) ASC"), :id).first
          transition_to!(round: next_round, question: first_q, status: :in_progress)
          return true
        else
          complete_game!
          return true
        end
      end

      false
    end
  end

  private

  def transition_to!(round:, question:, status: self.status)
    now = Time.current
    question.update!(shown_at: now) if question.present? && question.shown_at.nil?
    update!(
      status: status,
      current_round: round,
      current_question: question,
      question_started_at: Time.current
    )
  end

  def go_to_next_question(question)
    pos = question.position || 0
    current_round.questions
      .where("COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)", pos, pos, question.id)
      .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
      .first
  end

  def go_to_next_round(round)
    pos = round.position || 0
    rounds
      .where("COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)", pos, pos, round.id)
      .order(Arel.sql("COALESCE(position, 0) ASC"), :id)
      .first
  end

  def complete_game!
    update!(
      status: :completed,
      current_question: nil,
      question_started_at: nil
    )
  end

  def generate_game_code
    self.game_code = SecureRandom.hex(3).upcase
  end

  def populate_quiz_data
        QuizPopulator.call(self)
  end
end
