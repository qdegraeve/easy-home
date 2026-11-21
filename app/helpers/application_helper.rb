module ApplicationHelper
  # Line icon (see IconComponent): icon(:droplet), icon(:cloud_sun, class: "text-muted").
  def icon(name, **options)
    render(IconComponent.new(name, **options))
  end

  # Sets the page <title>, which the Hotwire Native shell shows in its top bar, and returns the text for the <h1>.
  def page_title(text)
    content_for(:title, text)
    text
  end

  EXPOSURE_ICONS = { "full_sun" => :sun, "partial_shade" => :cloud_sun, "shade" => :cloud }.freeze
  HEALTH_ICONS = {
    "ok" => [ :circle_check, "text-action" ],
    "watch" => [ :eye, "text-warn" ],
    "act" => [ :triangle_alert, "text-alert" ]
  }.freeze

  # Exposure of a location, with its icon: "☼ Plein soleil".
  def exposure_label(exposure)
    safe_join([ icon(EXPOSURE_ICONS.fetch(exposure.to_s), size: 16), t("locations.exposures.#{exposure}") ], " ")
  end

  # Section heading content: an icon then the text.
  def heading_with_icon(name, text, icon_class: "text-muted")
    safe_join([ icon(name, class: icon_class), text ], " ")
  end

  BUTTON_VARIANTS = {
    primary: "bg-action font-semibold text-white hover:bg-action-strong",
    secondary: "bg-action-soft font-semibold text-action hover:bg-subtle",
    tertiary: "font-semibold text-action hover:bg-subtle",
    danger: "font-semibold text-alert hover:bg-alert-soft"
  }.freeze

  # Classes of a button or a link styled as one (UX review, "Bouton"): 48 px high, one action color.
  # Destructive actions use :danger, always behind a confirmation.
  def button_class(variant = :primary, block: false)
    class_names(
      "inline-flex min-h-12 items-center justify-center gap-2 rounded-xl px-4 text-sm",
      BUTTON_VARIANTS.fetch(variant),
      "w-full": block
    )
  end

  # Small secondary action next to a row (edit, delete, cancel): small text, but a 44 px touch target.
  def small_action_class(tone = :muted)
    color = tone == :danger ? "text-alert hover:bg-alert-soft" : "text-muted hover:bg-subtle"
    "inline-flex min-h-11 items-center rounded-lg px-2 text-xs #{color}"
  end

  SECTIONS = {
    today: %w[home today/waterings],
    house: %w[house plants plants/tasks plants/photos plants/analyses plants/analysis_questions households locations],
    journal: %w[journal]
  }.freeze

  # The tab bar is shown once signed in with a household (not on the sign-in pages, nor on the first household form).
  # In the Android app, not on the pages opened as modals (path configuration): a tab would close the modal.
  def show_tabs?
    return @show_tabs if defined?(@show_tabs)

    @show_tabs = authenticated? && Current.user.present? && !(hotwire_native_app? && modal_page?) &&
      policy_scope(Household).exists?
  end

  # Pages the Android app opens as modals (config/hotwire/android_v1.json).
  def modal_page?
    request.path.match?(%r{/(new|edit)\z|\A/households\z|\A/today/watering\z})
  end

  # Section of the tab bar the current page belongs to (nil for the settings).
  def current_tab
    return if controller_path == "households" && action_name.in?(%w[index new create])

    SECTIONS.find { |_, paths| paths.include?(controller_path) }&.first
  end

  # "← …" link at the top of a page, for the browser only: in the Android app, the native top bar and the system
  # back already go back, and a web link would push a new screen instead of going back.
  def back_link_to(text, url)
    link_to(text, url, class: "text-sm text-muted underline") unless hotwire_native_app?
  end

  # Form data for a confirmed action: the message, the label of the confirm button (the action itself, not
  # "confirm"), and the danger tone for destructive actions. Read by app/javascript/lib/confirm_dialog.js.
  def confirm_data(message, button:, danger: false)
    { turbo_confirm: message, confirm_button: button, confirm_tone: ("danger" if danger) }.compact
  end
end
