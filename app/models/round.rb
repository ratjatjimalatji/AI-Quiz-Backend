class Round < ApplicationRecord
    has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :round
    accepts_nested_attributes_for :questions, allow_destroy: true

    enum :round_type, {
    qualifier:          0,
    player_vs_player:   1
  }

  def as_json(options = {})
    default_options = {
      include: {
        questions: {
          except: [ :correct_answer_ids ],
          include: :options
        }
      }
    }

    super(default_options.deep_merge(options))
  end
end
