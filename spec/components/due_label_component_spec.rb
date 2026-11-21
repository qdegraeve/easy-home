require "rails_helper"

RSpec.describe DueLabelComponent, type: :component do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 23:30")) { example.run } }

  {
    "2026-11-14 00:00" => "prévu il y a 2 j",
    "2026-11-15 00:00" => "prévu hier",
    "2026-11-16 00:00" => "aujourd'hui",
    "2026-11-17 00:00" => "demain",
    "2026-11-20 00:00" => "dans 4 j"
  }.each do |due_at, label|
    it "shows \"#{label}\" for an occurrence due on #{due_at}" do
      render_inline(described_class.new(due_at: Time.zone.parse(due_at)))

      expect(page).to have_text(label)
    end
  end

  it "stays calm for a late occurrence and stresses today" do
    render_inline(described_class.new(due_at: Time.zone.parse("2026-11-15 00:00")))
    expect(page).to have_no_css("span.text-alert")

    render_inline(described_class.new(due_at: Time.zone.parse("2026-11-16 00:00")))
    expect(page).to have_css("span.font-semibold", text: "aujourd'hui")
  end
end
