require "rails_helper"

RSpec.describe Recurrence::OnDemand do
  it "never has a due date, a period, nor a tolerance" do
    rule = Recurrence.build(type: "on_demand", config: {})

    expect(rule.next_due_at(last_completed_at: nil)).to be_nil
    expect(rule.next_due_at(last_completed_at: Time.current)).to be_nil
    expect(rule.period_days).to be_nil
    expect(rule).not_to be_dated
    expect(Tolerance.grace_days(importance: :critical, recurrence: rule)).to be_nil
  end
end
