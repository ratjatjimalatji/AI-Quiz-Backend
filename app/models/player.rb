class Player < ApplicationRecord
  has_secure_token :token
  belongs_to :game, counter_cache: true
  has_many :submissions, dependent: :destroy

POWER_UPS = %w[
    get_hundred_points
    double_points
    hide_half_wrong_answers
  ].freeze

  attribute :power_ups, :string, array: true, default: -> { POWER_UPS }

  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }

  def use_power!(power_name)
    return false unless power_ups.include?(power_name.to_s)

    self.power_ups = power_ups - [ power_name.to_s ]
    save!
  end
end
