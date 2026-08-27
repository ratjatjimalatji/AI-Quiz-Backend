class Game < ApplicationRecord
  before_validation :generate_game_code, on: :create

  belongs_to :host, class_name: "Host"
  has_many :players, dependent: :destroy
  has_many :rounds, dependent: :destroy

  validates :game_code, presence: true, uniqueness: true
  validates :player_limit, numericality: { greater_than: 0 }

  private

  def generate_game_code
    self.game_code = SecureRandom.hex(3).upcase
  end
end
