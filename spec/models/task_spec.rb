require "rails_helper"

RSpec.describe Task, type: :model do
  include ActiveJob::TestHelper

  it_behaves_like "a photo subject" do
    subject { create(:task, subject: nil, template_key: nil) }
  end

  it "takes no new photo once stopped" do
    expect(build(:task, active: false)).to be_archived
    expect(build(:task)).not_to be_archived
  end

  it { is_expected.to validate_presence_of(:title) }

  it "rejects a subject of another household" do
    task = build(:task, subject: create(:plant))

    expect(task).not_to be_valid
    expect(task.errors[:subject]).to be_present
  end

  it "keeps a subject whole or none (enforced by the database)" do
    task = create(:task, subject: nil, template_key: nil)

    expect { task.update_columns(subject_type: "Plant") }
      .to raise_error(ActiveRecord::StatementInvalid, /subject_whole/)
  end

  it "lists as to do only the active tasks with an open occurrence" do
    open_task = create(:task, subject: nil, template_key: nil)
    open_task.occurrences.create!(due_at: Time.current)
    create(:task, subject: nil, template_key: nil) # done one-off: no open occurrence
    stopped = create(:task, subject: nil, template_key: nil, active: false)
    stopped.occurrences.create!(due_at: Time.current)

    expect(described_class.to_do).to eq([ open_task ])
  end

  it "accepts a task without a subject" do
    expect(build(:task, subject: nil)).to be_valid
  end

  it "rejects an invalid recurrence" do
    expect(build(:task, interval_days: 0)).not_to be_valid
    expect(build(:task, recurrence_config: {})).not_to be_valid
  end

  it "never changes household" do
    task = create(:task)

    expect { task.update(household: create(:household)) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "accepts only one open occurrence at a time (enforced by the database)" do
    task = create(:task)
    create(:task_occurrence, task:)

    expect { create(:task_occurrence, task:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "has no reminder when done when needed" do
    task = build(:task, recurrence_type: :on_demand, recurrence_config: {}, reminder_minute: 19 * 60)

    expect(task).not_to be_valid
  end

  it "gives the last completion of each task, done ones only" do
    salt, rinse, never = Array.new(3) { create(:task, recurrence_type: :on_demand, recurrence_config: {}) }
    salt.occurrences.create!(status: :done, due_at: 2.days.ago, completed_at: 2.days.ago)
    last = salt.occurrences.create!(status: :done, due_at: 1.day.ago, completed_at: 1.day.ago)
    rinse.occurrences.create!(status: :missed, due_at: 1.day.ago, completed_at: 1.day.ago)

    expect(described_class.last_done_at_by_id([ salt, rinse, never ])).to eq(salt.id => last.completed_at)
  end
end
