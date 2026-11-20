# AI analyses of a plant: owner and member, like the plant itself. An archived plant gets no new analysis, and its
# analyses' proposals cannot be accepted; only a finished analysis has proposals.
class PlantAnalysisPolicy < ApplicationPolicy
  def show?
    PlantPolicy.new(user, record.plant).show?
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
