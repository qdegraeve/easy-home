# Photos of an equipment or of a task (ADR 0016): added in one gesture, seen in large, deleted. The subject comes from
# the URL only (equipment/:equipment_id/photos, tasks/:task_id/photos), through policy_scope; each photo is looked up
# among the subject's own. The photos of a plant keep their own viewer (Plants::PhotosController).
class SubjectPhotosController < ApplicationController
  SUBJECTS = { equipment_id: Equipment, task_id: Task }.freeze

  def create
    subject = find_subject
    authorize Photo.new(subject:)
    result = Photos::Add.new.call(subject:, file: params.expect(photo: [ :file ])[:file])

    if result.success?
      redirect_to helpers.photos_home_path(subject), notice: t(".success")
    else
      code, upload = result.failure
      alert = code == :invalid ? upload.errors.full_messages.to_sentence : t(".#{code}")
      redirect_to helpers.photos_home_path(subject), alert:
    end
  end

  def show
    @subject = find_subject
    @photo = find_photo(@subject)
  end

  def destroy
    subject = find_subject
    photo = find_photo(subject, :destroy?)
    photo.destroy!
    # From a task sheet (a modal in the app), back to it; in the app, the photo screen is dismissed.
    flash[:notice] = t(".success")
    if subject.is_a?(Task)
      recede_or_redirect_to helpers.photos_home_path(subject), status: :see_other
    else
      redirect_to helpers.photos_home_path(subject), status: :see_other
    end
  end

  private

  def find_subject
    key, model = SUBJECTS.find { |param, _| request.path_parameters.key?(param) }
    policy_scope(model).find(request.path_parameters[key])
  end

  def find_photo(subject, query = :show?)
    subject.photos.find(params[:id]).tap { |photo| authorize photo, query }
  end
end
