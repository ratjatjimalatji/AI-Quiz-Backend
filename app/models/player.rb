class Player < ApplicationRecord
  has_secure_token :token
  belongs_to :game
  has_many :submissions, dependent: :destroy

  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }
end
