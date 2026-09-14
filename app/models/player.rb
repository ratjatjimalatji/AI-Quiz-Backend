class Player < ApplicationRecord
  has_secure_token :token
  belongs_to :game, counter_cache: true
  has_many :submissions, dependent: :destroy

  validates :username, presence: true
  validates :username, uniqueness: { scope: :game_id }
end
