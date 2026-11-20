# A follow-up question on an analysis, with an optional new photo of the plant.
class QuestionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :body, :string
  attr_accessor :photo

  validates :body, presence: true, length: { maximum: 1000 }
  validate :photo_must_be_a_picture

  def self.model_name
    ActiveModel::Name.new(self, nil, "PlantAnalysisQuestion")
  end

  private

  def photo_must_be_a_picture
    return if photo.blank?

    upload = PhotoUpload.new(file: photo)
    upload.errors.messages_for(:file).each { |message| errors.add(:photo, message) } unless upload.valid?
  end
end
