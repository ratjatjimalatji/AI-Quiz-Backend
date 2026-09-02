class Round < ApplicationRecord
    belongs_to :game, optional: true
    has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :round
    has_many :submissions, dependent: :destroy
    accepts_nested_attributes_for :questions, allow_destroy: true

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
