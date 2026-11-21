# A titled group of rows on a white surface, separated by hairlines, without shadow (UX review, "Groupe de liste").
#
#   render ListGroupComponent.new(title: "Journal", id: "journal", icon: :history) do |group|
#     group.with_row { "…" }
#   end
#
# Without rows, the block content is shown instead (an empty state).
class ListGroupComponent < ViewComponent::Base
  renders_many :rows

  def initialize(title: nil, id: nil, icon: nil, icon_class: "text-muted", heading: :h2)
    @title = title
    @id = id
    @icon = icon
    @icon_class = icon_class
    @heading = heading
  end

  private

  attr_reader :title, :id, :icon, :icon_class, :heading
end
