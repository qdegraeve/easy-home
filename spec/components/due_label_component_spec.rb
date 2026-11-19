require "rails_helper"

RSpec.describe DueLabelComponent, type: :component do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 23:30")) { example.run } }

  {
    "2026-11-14 00:00" => "en retard de 2 j",
    "2026-11-15 00:00" => "en retard de 1 j",
    "2026-11-16 00:00" => "aujourd'hui",
    "2026-11-17 00:00" => "demain",
    "2026-11-20 00:00" => "dans 4 j"
  }.each do |due_at, label|
    it "shows \"#{label}\" for an occurrence due on #{due_at}" do
      render_inline(described_class.new(due_at: Time.zone.parse(due_at)))

      expect(page).to have_text(label)
    end
  end

  it "highlights a late occurrence" do
    render_inline(described_class.new(due_at: Time.zone.parse("2026-11-15 00:00")))

    expect(page).to have_css("span.text-red-700")
  end
end
