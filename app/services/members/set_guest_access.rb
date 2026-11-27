module Members
  # What a guest may see and do (ADR 0019): the subjects opened (plants, equipment, "Household" for the tasks of the
  # house), or all of them, and the optional period. Replaces the previous settings. Used when inviting a guest and
  # from their page.
  #
  #   params: { full_access: "1", starts_on: "2026-12-20", ends_on: "2027-01-05", subjects: ["Plant:3", "Household:1"] }
  class SetGuestAccess
    include Dry::Monads[:result]

    def call(member:, params:)
      member.assign_attributes(
        guest_full_access: ActiveModel::Type::Boolean.new.cast(params[:full_access]) || false,
        access_starts_on: params[:starts_on].presence,
        access_ends_on: params[:ends_on].presence
      )
      subjects = find_subjects(member.household, Array(params[:subjects]))
      return Failure[:invalid, member] unless member.valid? & dates_valid?(member, params)

      ActiveRecord::Base.transaction do
        member.save!
        member.guest_accesses.where.not(id: subjects.filter_map { keep(member, _1) }).delete_all
        subjects.each { |subject| member.guest_accesses.find_or_create_by!(subject:) }
      end
      Success(member)
    end

    private

    # Only the subjects of this household; anything else in the params is ignored.
    def find_subjects(household, keys)
      keys.filter_map do |key|
        type, id = key.to_s.split(":", 2)
        case type
        when "Household" then household if id.to_i == household.id
        when "Plant" then household.plants.find_by(id:)
        when "Equipment" then household.equipment.find_by(id:)
        end
      end.uniq
    end

    def keep(member, subject)
      member.guest_accesses.find_by(subject:)&.id
    end

    # A date given but unreadable must not silently open the access without end.
    def dates_valid?(member, params)
      { access_starts_on: :starts_on, access_ends_on: :ends_on }.each do |attribute, key|
        member.errors.add(attribute, :invalid) if params[key].present? && member.public_send(attribute).nil?
      end
      member.errors.none?
    end
  end
end
