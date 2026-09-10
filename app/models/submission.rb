class Submission < ApplicationRecord
  belongs_to :player
  belongs_to :question
  belongs_to :round
end
