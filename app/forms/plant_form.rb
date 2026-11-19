# Input for a plant and its watering: covers Plant and its watering Task.
class PlantForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :species, :string
  attribute :location_id, :integer
  attribute :watering_interval_days, :integer
  attribute :last_watered_on, :date, default: -> { Time.zone.today }

  attr_accessor :household, :photo

  validates :name, presence: true, length: { maximum: 100 }
  validates :species, length: { maximum: 100 }
  validates :watering_interval_days, numericality: { only_integer: true, in: Recurrence::Sliding::INTERVAL_DAYS }
  validates :last_watered_on,
    comparison: { less_than_or_equal_to: -> { Time.zone.today } },
    allow_nil: true,
    on: :create
  validate :location_must_belong_to_household
  validate :photo_must_be_a_picture, on: :create

  def self.model_name = ActiveModel::Name.new(self, nil, "Plant")

  def self.from(plant)
    new(
      household: plant.household,
      name: plant.name,
      species: plant.species,
      location_id: plant.location_id,
      watering_interval_days: plant.watering_task&.recurrence_config&.dig("interval_days")
    )
  end

  def plant_attributes
    { name: name.strip, species: species.to_s.strip.presence, location_id: }
  end

  def watering_recurrence_config
    { "interval_days" => watering_interval_days }
  end

  private

  def photo_must_be_a_picture
    return if photo.blank?

    upload = PhotoUpload.new(file: photo)
    upload.errors.messages_for(:file).each { |message| errors.add(:photo, message) } unless upload.valid?
  end

  def location_must_belong_to_household
    return if location_id.nil? || household&.locations&.exists?(location_id)

    errors.add(:location_id, :inclusion)
  end
end
