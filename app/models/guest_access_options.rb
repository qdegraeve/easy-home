# The subjects that can be opened to a guest, for the form (members/_guest_access): the tasks of the house, then the
# active plants and the equipment of the household, each with its key ("Plant:3").
class GuestAccessOptions
  Option = Data.define(:key, :label, :group)

  def initialize(household)
    @household = household
  end

  def each(&)
    options.each(&)
  end

  def options
    @options ||= [ Option.new("Household:#{@household.id}", I18n.t("members.guest_access.house_tasks"), :house) ] +
      @household.plants.active.order(:name).map { Option.new("Plant:#{_1.id}", _1.name, :plants) } +
      @household.equipment.order(:name).map { Option.new("Equipment:#{_1.id}", _1.name, :equipment) }
  end

  # The keys opened to this guest.
  def selected(member)
    member.guest_accesses.map { "#{_1.subject_type}:#{_1.subject_id}" }
  end
end
