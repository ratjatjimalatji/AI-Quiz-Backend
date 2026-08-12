class Game < ApplicationRecord

  has_many :players , dependent: :destroy
  has_many :rounds , dependent: :destroy

  def host
    players.find_by(is_host: true)
  end
end
