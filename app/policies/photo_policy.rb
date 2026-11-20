# Photos of a plant: owner and member manage them, like the plant itself. An archived plant gets no new photo.
class PhotoPolicy < ApplicationPolicy
  def show? = PlantPolicy.new(user, record.plant).show?
  def create? = show? && !record.plant.archived?
  def destroy? = show?
end
