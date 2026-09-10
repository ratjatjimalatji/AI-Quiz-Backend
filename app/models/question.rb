class Question < ApplicationRecord
  belongs_to :round, inverse_of: :questions, optional: true
  has_many :options, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  has_many :submissions, dependent: :destroy
  accepts_nested_attributes_for :options, allow_destroy: true

  enum :question_type, {
    true_false:      0,
    single_choice:   1,
    multiple_choice: 2,
    drag_drop_order: 3,
    type_the_answer: 4
  }

  def as_json(options = {})
    default_options = {
      except: [ :correct_answer_ids ],
      include: :options
    }
    super(default_options.deep_merge(options))
  end

  before_validation :set_default_correct_answer_ids, on: :create

  private

  def set_default_correct_answer_ids
    return if correct_answer_ids.present?

    self.correct_answer_ids = []
  end
end
