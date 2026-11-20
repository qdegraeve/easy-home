# A phone registers for push notifications within the signed-in session it comes from.
class ApplicationPushDevicePolicy < ApplicationPolicy
  def create?
    record.owner.is_a?(Session) && record.owner.user == user
  end
end
