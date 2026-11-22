# The user's notification settings: the morning digest on or off, its time (quarter hours, app time zone), whether it
# lists only the tasks that must not be missed, and the households it covers among those the user manages.
class NotificationSettingsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :digest_enabled, :boolean
  attribute :digest_time, :string
  attribute :critical_only, :boolean
  attr_accessor :user
  attr_writer :household_ids

  validates :digest_enabled, :critical_only, inclusion: { in: [ true, false ] }
  validates :digest_time, inclusion: { in: ->(_form) { times } }
  validate :households_must_be_managed

  def self.model_name
    ActiveModel::Name.new(self, nil, "NotificationSettings")
  end

  def self.times
    User::DIGEST_MINUTES.map { |minute| format("%02d:%02d", *minute.divmod(60)) }
  end

  def self.from(user)
    new(
      user:,
      digest_enabled: user.digest_enabled,
      digest_time: format("%02d:%02d", *user.digest_minute.divmod(60)),
      critical_only: user.digest_critical?,
      household_ids: memberships(user).where(digest: true).pluck(:household_id)
    )
  end

  # Guests have no task list of their own: only the households the user manages can be followed.
  def self.memberships(user)
    user.household_members.where.not(role: :guest).includes(:household).order("households.name")
  end

  def memberships
    self.class.memberships(user)
  end

  def household_ids
    Array(@household_ids).compact_blank.map(&:to_i).uniq
  end

  def digest_minute
    hours, minutes = digest_time.split(":").map(&:to_i)
    (hours * 60) + minutes
  end

  private

  def households_must_be_managed
    errors.add(:household_ids, :invalid) unless (household_ids - memberships.pluck(:household_id)).empty?
  end
end
