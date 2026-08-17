class Host < ApplicationRecord
  has_secure_token :token
  has_many :games, dependent: :destroy
  has_many :players, through: :games

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true
end
