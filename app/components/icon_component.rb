# Line icon from the Lucide set (ISC license), drawn inline so that it takes the text color (`currentColor`).
# The SVG files are copied in app/assets/images/icons (lucide-static, see the LICENSE there): add a file to use a new
# icon. Decorative by default (hidden from screen readers, the text next to it says the same); pass `label:` for an
# icon that stands alone.
class IconComponent < ViewComponent::Base
  DIRECTORY = Rails.root.join("app/assets/images/icons")
  SHAPES = Dir[DIRECTORY.join("*.svg")].to_h do |path|
    [ File.basename(path, ".svg"), File.read(path)[%r{<svg[^>]*>(.*)</svg>}m, 1].strip.html_safe ]
  end.freeze

  def initialize(name, size: 20, label: nil, class: nil)
    @name = name.to_s.tr("_", "-")
    @shape = SHAPES.fetch(@name) { raise ArgumentError, "Unknown icon #{name.inspect} (#{DIRECTORY})" }
    @size = size
    @label = label
    @css_class = binding.local_variable_get(:class)
  end

  def call
    tag.svg(
      @shape,
      xmlns: "http://www.w3.org/2000/svg",
      width: @size,
      height: @size,
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.75,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      class: [ "inline-block shrink-0 align-[-0.2em]", @css_class ],
      role: @label ? "img" : nil,
      "aria-label": @label,
      "aria-hidden": @label ? nil : "true",
      data: { icon: @name } # which icon it is, for the specs and the eye
    )
  end
end
