require "rails_helper"

RSpec.describe IconComponent, type: :component do
  it "draws a Lucide icon inline, in the text color, hidden from screen readers" do
    render_inline(described_class.new(:droplet, class: "text-plants"))

    svg = page.find("svg", visible: :all)
    expect(svg[:"aria-hidden"]).to eq("true")
    expect(svg[:stroke]).to eq("currentColor")
    expect(svg[:class]).to include("text-plants")
    expect(svg).to have_css("path", visible: :all)
  end

  it "names a standalone icon for screen readers" do
    render_inline(described_class.new(:bell, label: "Notifications", size: 24))

    svg = page.find("svg[role=img]", visible: :all)
    expect([ svg[:"aria-label"], svg[:width], svg[:"aria-hidden"] ]).to eq([ "Notifications", "24", nil ])
  end

  it "refuses an icon that was not copied in the project" do
    expect { described_class.new(:unicorn) }.to raise_error(ArgumentError, /Unknown icon :unicorn/)
  end

  it "uses only icons that exist, in the views and in the icon tables of the helpers" do
    used = Rails.root.glob("app/{views,components,helpers}/**/*.{erb,rb}").flat_map do |file|
      # icon(:name), heading_with_icon(:name, …) and icon(condition ? :one : :other)
      call = /(?:IconComponent\.new|\bicon|heading_with_icon)\((?:[^,()]*\? )?:([a-z0-9_]+)(?: : :([a-z0-9_]+))?/
      File.read(file).scan(call).flatten.compact
    end
    used += ApplicationHelper::EXPOSURE_ICONS.values + ApplicationHelper::HEALTH_ICONS.values.map(&:first)

    expect(used.map { |name| name.to_s.tr("_", "-") }.uniq - described_class::SHAPES.keys).to be_empty
    expect(used.map(&:to_s)).to include("droplet", "check", "triangle_alert")
  end
end
