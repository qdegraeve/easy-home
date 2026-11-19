require "rails_helper"

RSpec.describe Task, type: :model do
  it { is_expected.to validate_presence_of(:title) }

  it "refuse un sujet d'un autre foyer" do
    task = build(:task, subject: create(:plant))

    expect(task).not_to be_valid
    expect(task.errors[:subject]).to be_present
  end

  it "accepte une tâche sans sujet" do
    expect(build(:task, subject: nil)).to be_valid
  end

  it "refuse une récurrence invalide" do
    expect(build(:task, interval_days: 0)).not_to be_valid
    expect(build(:task, recurrence_config: {})).not_to be_valid
  end

  it "ne change jamais de foyer" do
    task = create(:task)

    expect { task.update(household: create(:household)) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "n'accepte qu'une échéance ouverte à la fois (garantie en base)" do
    task = create(:task)
    create(:task_occurrence, task:)

    expect { create(:task_occurrence, task:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
