# Photos of a subject (a plant for now; an equipment and a task to come): seeing a photo is seeing its subject;
# adding one, changing its date or deleting it is changing the subject (a guest who may see a task will not touch its
# photos). An archived subject gets no new photo. A photo without a known subject is refused.
class PhotoPolicy < ApplicationPolicy
  def show?
    subject_allows?(:show?)
  end

  def create?
    subject_allows?(:update?) && !subject_archived?
  end

  def update?
    subject_allows?(:update?)
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  private

  def subject_allows?(query)
    return false unless record.subject && Photo::SUBJECT_TYPES.include?(record.subject_type)

    Pundit.policy!(user, record.subject).public_send(query)
  end

  def subject_archived?
    record.subject.respond_to?(:archived?) && record.subject.archived?
  end
end
