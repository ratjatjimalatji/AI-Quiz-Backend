class Game < ApplicationRecord
  # The leaderboard is shown after this question number within a round.
  LEADERBOARD_QUESTION_FREQUENCY_NUMBER = 4

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
    with_lock { perform_advance! }
  end

  def should_show_leaderboard?
    question_number_in_round % LEADERBOARD_QUESTION_FREQUENCY_NUMBER.zero?
  end

  def last_question_of_round?
    current_question.present? && go_to_next_question(current_question).nil?
  end

  private

  def perform_advance!
    return false if completed?
    return start_game! if waiting? || current_round.nil?

    case status
    when "in_progress"
      advance_from_question!
    when "leaderboard"
      advance_from_leaderboard!
    when "round_summary"
      start_next_round!
    else
      false
    end
  end

  def start_game!
    first_round = ordered_rounds.first
    return false unless first_round

    first_question = ordered_questions(first_round).first
    return false unless first_question

    transition_to!(round: first_round, question: first_question, status: :in_progress)
    true
  end

  def advance_from_question!
    return false if current_question.nil?

    if last_question_of_round?
      display_leaderboard!(:round_summary)
    elsif should_show_leaderboard?
      display_leaderboard!(:leaderboard)
    else
      advance_to_next_question!
    end
  end

  def advance_from_leaderboard!
    last_question_of_round? ? start_next_round! : advance_to_next_question!
  end

  def advance_to_next_question!
    next_question = go_to_next_question(current_question)
    return false unless next_question

    transition_to!(round: current_round, question: next_question, status: :in_progress)
    true
  end

  def start_next_round!
    next_round = go_to_next_round(current_round)

    if next_round.present?
      first_question = ordered_questions(next_round).first
      return false unless first_question

      transition_to!(round: next_round, question: first_question, status: :in_progress)
    else
      complete_game!
    end
    true
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def display_leaderboard!(target_status)
    DisplayLeaderboardService.call(
      game: self,
      current_round: current_round,
      current_question: current_question
    )

    # Make sure the status is exactly what we want, regardless of what the
    # service did, so the next advance_step! knows where it is.
    reload
    update!(status: target_status, question_started_at: Time.current)
    true
  end

  def transition_to!(round:, question:, status: self.status)
    now = Time.current
    question.update!(shown_at: now) if question.present? && question.shown_at.nil?
    update!(
      status: status,
      current_round: round,
      current_question: question,
      question_started_at: now
    )
  end

  def complete_game!
    update!(
      status: :completed,
      current_question: nil,
      question_started_at: nil
    )
  end

  def ordered_rounds
    rounds.reorder(Arel.sql("COALESCE(position, 0) ASC"), :id)
  end

  def ordered_questions(round)
    round.questions.reorder(Arel.sql("COALESCE(position, 0) ASC"), :id)
  end

  # 1-based position of the current question within the current round.
  def question_number_in_round
    return nil if current_round.nil? || current_question.nil?

    index = ordered_questions(current_round).pluck(:id).index(current_question.id)
    index && index + 1
  end

  def go_to_next_question(question)
    pos = question.position || 0
    ordered_questions(current_round)
      .where("COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)", pos, pos, question.id)
      .first
  end

  def go_to_next_round(round)
    pos = round.position || 0
    ordered_rounds
      .where("COALESCE(position, 0) > ? OR (COALESCE(position, 0) = ? AND id > ?)", pos, pos, round.id)
      .first
  end

  def generate_game_code
    self.game_code = SecureRandom.hex(3).upcase
  end

  def populate_quiz_data
    QuizPopulator.call(self)
  end
end
