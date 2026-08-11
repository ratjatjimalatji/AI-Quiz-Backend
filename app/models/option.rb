class Option < ApplicationRecord
  belongs_to :question, inverse_of: :options, optional: true

end
