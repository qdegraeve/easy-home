# Nothing to show yet: a line icon, one sentence, optionally an action (UX review, "État vide"). No giant emoji.
class EmptyStateComponent < ViewComponent::Base
  def initialize(text:, icon: nil, title: nil)
    @text = text
    @icon = icon
    @title = title
  end

  def call
    tag.div(class: class_names("rounded-2xl bg-surface p-4 text-sm text-muted", "text-center": @icon)) do
      safe_join([
        (helpers.icon(@icon, size: 32, class: "mx-auto mb-2 block") if @icon),
        (tag.p(@title, class: "font-semibold text-ink") if @title),
        tag.p(@text),
        (tag.div(content, class: "mt-3") if content?)
      ].compact)
    end
  end
end
