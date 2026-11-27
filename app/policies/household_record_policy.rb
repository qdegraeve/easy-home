# What belongs to a household and is managed like it (a plant, an equipment): its managers and members see and
# change it; a guest sees it, read only, when it is opened to them (ADR 0019, GuestVisibilityQuery).
class HouseholdRecordPolicy < ApplicationPolicy
  def show?
    manage? || opened_to_guest?
  end

  def create?
    manage?
  end

  def new?
    manage?
  end

  def update?
    manage?
  end

  def edit?
    manage?
  end

  def destroy?
    manage?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      opened = GuestVisibilityQuery.new(user).subjects(scope.all.klass).select(:id)
      scope.where(household_id: managed_household_ids).or(scope.where(id: opened))
    end
  end

  private

  def manage?
    HouseholdPolicy.new(user, record.household).manage?
  end

  def opened_to_guest?
    record.persisted? && GuestVisibilityQuery.new(user).subjects(record.class).exists?(record.id)
  end
end
