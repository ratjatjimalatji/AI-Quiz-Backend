class Question < ApplicationRecord
  belongs_to :round, inverse_of: :questions, optional: true
  has_many :options, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  accepts_nested_attributes_for :options, allow_destroy: true

  enum :question_type, {
    true_false:      0,
    single_choice:   1,
    multiple_choice: 2,
    drag_drop_order: 3
  }
  before_validation :set_default_correct_answer_ids, on: :create
  before_validation :set_default_round_id, on: :create

  private

  def set_default_correct_answer_ids
    return if correct_answer_ids.present?

    self.correct_answer_ids = []
  end

  def set_default_round_id
    return if round_id.present?

    self.round_id = nil
  end
end
