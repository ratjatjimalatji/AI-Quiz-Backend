class Player < ApplicationRecord
  has_secure_token :token
  belongs_to :game, counter_cache: true
  has_many :submissions, dependent: :destroy

SUPER_POWERS = %w[
    get_hundred_points
    double_points
    hide_half_wrong_answers
  ].freeze

  attribute :super_powers, :string, array: true, default: -> { SUPER_POWERS }

  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }

  def use_power!(power_name)
    return false unless super_powers.include?(power_name.to_s)

    self.super_powers = super_powers - [ power_name.to_s ]
    save!
  end
end
