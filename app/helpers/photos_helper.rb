# Where the photos of a subject live: the Photos tab of an equipment, the sheet of a task.
module PhotosHelper
  def photos_home_path(subject)
    subject.is_a?(Task) ? task_path(subject) : polymorphic_path(subject, tab: "photos")
  end

  # The name shown for the subject of a photo: a task by its title.
  def photo_subject_name(subject)
    subject.is_a?(Task) ? subject.title : subject.name
  end
end
