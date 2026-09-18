class Option < ApplicationRecord
  belongs_to :question, inverse_of: :options
  has_many :submissions, dependent: :destroy
  has_one_attached :image

  def as_json(options = {})
    super(options.merge(methods: :image_url))
  end

  def image_url
    image.attached? ? image.url : nil
  end
end
