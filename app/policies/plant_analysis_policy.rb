# AI analyses of a plant: owner and member, like the plant itself. An archived plant gets no new analysis.
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
end
