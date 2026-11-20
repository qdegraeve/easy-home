# A user only manages their own settings.
class UserPolicy < ApplicationPolicy
  def edit?
    update?
  end

  def update?
    record == user
  end
end
