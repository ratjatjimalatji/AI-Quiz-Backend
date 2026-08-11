class Question < ApplicationRecord
  has_many :options, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  accepts_nested_attributes_for :options, allow_destroy: true

  enum :question_type, {
    true_false:      0,
    single_choice:   1,
    multiple_choice: 2,
    drag_drop_order: 3
  }
  before_validation :set_default_correct_answer_ids, on: :create

  private

  def set_default_correct_answer_ids
    # Only set defaults if the attribute is currently empty or nil
    return if correct_answer_ids.present?

    # Initialize correct_answer_ids as an array
    self.correct_answer_ids = [1]
  end
end 
