# Photos of a subject (a plant for now; an equipment and a task to come): those who can see the subject manage its
# photos. An archived subject gets no new photo.
class PhotoPolicy < ApplicationPolicy
  def show?
    Pundit.policy!(user, record.subject).show?
  end

  def create?
    show? && !subject_archived?
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
    show?
  end

  private

  def subject_archived?
    record.subject.respond_to?(:archived?) && record.subject.archived?
  end
end
