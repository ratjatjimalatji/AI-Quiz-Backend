class Game < ApplicationRecord
  belongs_to :host, class_name: "User"

  has_many :players
  has_many :rounds
end
