class Round < ApplicationRecord
    belongs_to :game, optional: true
    has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :round
    accepts_nested_attributes_for :questions, allow_destroy: true

    enum :round_type, {
    qualifier:          0,
    player_vs_player:   1
  }
end
