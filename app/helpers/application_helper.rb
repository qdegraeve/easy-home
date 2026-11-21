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
    [ "inline-flex min-h-12 items-center justify-center gap-2 rounded-xl px-4 text-sm", BUTTON_VARIANTS.fetch(variant),
      ("w-full" if block) ].compact.join(" ")
  end

  # Small secondary action next to a row (edit, delete, cancel): small text, but a 44 px touch target.
  def small_action_class(tone = :muted)
    color = tone == :danger ? "text-alert hover:bg-alert-soft" : "text-muted hover:bg-subtle"
    "inline-flex min-h-11 items-center rounded-lg px-2 text-xs #{color}"
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
