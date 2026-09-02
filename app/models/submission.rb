class Submission < ApplicationRecord
  belongs_to :player
  belongs_to :question
  belongs_to :round

  validates :response_time_ms, presence: true
  validates :points_awarded, presence: true
  validates :correct, inclusion: { in: [ true, false ] }
  validates :player_id, uniqueness: { scope: [ :question_id, :round_id ] }
end
