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
    leaderboard: "leaderboard",
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
        if should_show_leaderboard?
          DisplayLeaderboardService.call(game: self, current_round: current_round, current_question: current_question)
          update!(status: :leaderboard)
          return true
        end
        return advance_to_next_content!
      end

      if leaderboard?
        return advance_to_next_content!
      end

      if round_summary?
        return start_next_round!
      end
    end
    false
  end

  def questions_shown_count
    Question.joins(:round).where(rounds: { game_id: id }).where.not(shown_at: nil).count
  end

  # Checks if we just finished an even-numbered question batch
  def should_show_leaderboard?
    count = questions_shown_count
    count.positive? && (count % 4).zero? && (count % 10).nonzero?
  end

  private

  def advance_to_next_content!
    next_question = go_to_next_question(current_question)

    if next_question.present?
      transition_to!(round: current_round, question: next_question, status: :in_progress)
      true
    else
      next_round = go_to_next_round(current_round)
      if next_round.present?
        RoundTransitionService.call(self)
        true
      else
        complete_game!
        true
      end
    end
  end

  def start_next_round!
    next_round = go_to_next_round(current_round)

    if next_round.present?
      first_q = next_round.questions.order(Arel.sql("COALESCE(position, 0) ASC"), :id).first
      transition_to!(round: next_round, question: first_q, status: :in_progress)
      true
    else
      complete_game!
      true
    end
  end

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
