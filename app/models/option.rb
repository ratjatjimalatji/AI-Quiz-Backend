class Option < ApplicationRecord
  belongs_to :question, inverse_of: :options
  has_many :submissions, dependent: :destroy
end
