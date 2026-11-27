# AI analyses of a plant: managers and members, who manage the plant; not a guest, even with the plant opened.
# An archived plant gets no new analysis, and its
# analyses' proposals cannot be accepted; only a finished analysis has proposals.
class PlantAnalysisPolicy < ApplicationPolicy
  def show?
    PlantPolicy.new(user, record.plant).update?
  end

  def create?
    show? && !record.plant.archived?
  end

  def new?
    create?
  end

  def accept?
    create? && record.done?
  end
end
