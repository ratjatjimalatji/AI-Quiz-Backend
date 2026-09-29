class Player < ApplicationRecord
  has_secure_token :token
  belongs_to :game, counter_cache: true
  has_many :submissions, dependent: :destroy

POWER_UPS = %w[
    get_hundred_points
    double_points
    glitch_sabotage
  ].freeze

  attribute :power_ups, :string, array: true, default: -> { POWER_UPS }
  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }

  def can_use_power_up?(power_name, question)
    return false unless power_ups.include?(power_name.to_s)
    return false if submissions.exists?(question_id: question.id)
    return false unless game_state_allows_submission?
    true
  end

  # Activates a deferred power-up (e.g., double_points)
  def activate_deferred_power_up!(power_name, question)
    return false unless can_use_power_up?(power_name, question)
    return false if active_power_up.present?

    transaction do
      self.power_ups = power_ups - [ power_name.to_s ]
      self.active_power_up = power_name.to_s
      self.active_power_up_question_id = question.id
      save!
    end
    true
  end

  # Atomically consumes and resets the active power-up during submission
  def consume_active_power_up!(question)
    return nil unless active_power_up_question_id == question.id

    power = active_power_up
    update!(active_power_up: nil, active_power_up_question_id: nil)
    power
  end

  private

  def game_state_allows_submission?
    # Ensure game is in active answer window (between question start and review)
    # Adjust to your game status column or timestamp logic
    game.status == "in_progress" or game.status == "question_review"
  end
end
