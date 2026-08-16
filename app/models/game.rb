class Game < ApplicationRecord
  before_validation :generate_game_code, on: :create

  belongs_to :host, class_name: "Host"
  has_many :players, dependent: :destroy
  has_many :rounds, dependent: :destroy

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  private

  def generate_game_code
    self.game_code = SecureRandom.hex(6).upcase
  end
end
