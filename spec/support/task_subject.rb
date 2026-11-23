# Contract of a subject of tasks (ADR 0010, 0016): a plant, an equipment. Same household as its tasks, a name, an
# archived? answer, and its tasks deleted with it, with their history.
RSpec.shared_examples "a task subject" do
  it "names itself, answers archived?, and deletes its tasks and their history with it" do
    task = create(:task, household: subject.household, subject:, template_key: nil, title: "Entretenir")
    task.occurrences.create!(due_at: Time.current, status: :done, completed_at: Time.current)

    expect(subject.name).to be_present
    expect(subject.archived?).to be_in([ true, false ])
    expect(subject.tasks).to include(task)
    expect { subject.update!(household: create(:household)) }.to raise_error(ActiveRecord::ActiveRecordError)

    subject.destroy!

    expect(Task.where(id: task.id)).to be_empty
    expect(TaskOccurrence.where(task_id: task.id)).to be_empty
  end
end
