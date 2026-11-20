# Photos of a plant: owner and member manage them, like the plant itself. An archived plant gets no new photo.
class PhotoPolicy < ApplicationPolicy
  def show?
    PlantPolicy.new(user, record.plant).show?
  end

  def create?
    show? && !record.plant.archived?
  end

  def update?
    show?
  end

  def destroy?
    show?
  end
end
