class Player < ApplicationRecord
  belongs_to :game

  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }
end
