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

  # A place recorded on an analysis (Plant#place): "mi-ombre, abrité du vent", "sans emplacement".
  def place_label(place)
    return t("places.none") unless place["exposure"]

    exposure = t("locations.exposures.#{place['exposure']}").downcase
    shelter = t(place["sheltered"] ? "places.sheltered" : "places.exposed")
    "#{exposure}, #{shelter}"
  end

  # Section heading content: an icon then the text.
  def heading_with_icon(name, text, icon_class: "text-muted")
    safe_join([ icon(name, class: icon_class), text ], " ")
  end

  BUTTON_VARIANTS = {
    primary: "bg-action font-semibold text-white hover:bg-action-strong active:bg-action-strong",
    secondary: "bg-action-soft font-semibold text-action hover:bg-subtle active:bg-subtle",
    tertiary: "font-semibold text-action hover:bg-subtle active:bg-subtle",
    danger: "font-semibold text-alert hover:bg-alert-soft active:bg-alert-soft",
    # On the dark photo viewer: white text, the danger tone is carried by the confirmation.
    on_dark: "font-semibold text-white/90 hover:bg-white/10 focus-visible:outline-2 focus-visible:outline-offset-2 " \
             "focus-visible:outline-white"
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
    color = if tone == :danger
      "text-alert hover:bg-alert-soft active:bg-alert-soft"
    else
      "text-muted hover:bg-subtle active:bg-subtle"
    end
    "inline-flex min-h-11 items-center rounded-xl px-2 text-sm #{color}"
  end

  # "Basilic, Citronnier et Menthe", or "Basilic, Citronnier et 2 autres" past three names: a sentence stays short.
  def names_sentence(names)
    shown = names.size > 3 ? names.first(2) + [ t("names_sentence.others", count: names.size - 2) ] : names
    shown.to_sentence(words_connector: ", ", two_words_connector: " et ", last_word_connector: " et ")
  end

  # Round "done" button of a list row (design review): an empty circle, an action still to do, that fills on press
  # and while the request is sent (Turbo disables the button), never filled at rest, which would read as "done".
  def done_button_class
    "grid size-11 shrink-0 place-items-center rounded-full border-2 border-action bg-surface text-action " \
      "hover:bg-action-soft active:bg-action active:text-white disabled:bg-action disabled:text-white"
  end

  # A <summary> that folds a list (design review): no browser triangle, a chevron that turns when open (the parent
  # <details> carries `group/fold`, a named group, so that other groups do not mix). Used with `summary_chevron`.
  def summary_class
    "-mx-1 flex min-h-11 cursor-pointer list-none items-center gap-1.5 rounded-xl px-1 py-2 font-semibold " \
      "[&::-webkit-details-marker]:hidden"
  end

  def summary_chevron
    icon(
      :chevron_down,
      size: 16,
      class: "text-muted transition-transform group-open/fold:rotate-180 motion-reduce:transition-none"
    )
  end

  # Small action of a row, like "Reporter" or a proposal of an analysis: a bordered pill, so it reads as a button and
  # not as a date, inside a 44 px touch target (the inner span carries the pill; a named group, so that an outer
  # group never lights it up). Accepted, the same pill filled, with a check.
  def chip_class
    "group/chip inline-flex min-h-11 shrink-0 items-center"
  end

  def chip_inner_class
    "inline-flex h-8 items-center gap-1 whitespace-nowrap rounded-full border border-field px-3 text-sm font-medium " \
      "text-ink group-hover/chip:bg-subtle group-active/chip:bg-subtle"
  end

  def accepted_chip_class
    "inline-flex h-8 items-center gap-1 whitespace-nowrap rounded-full bg-action-soft px-3 text-sm font-medium " \
      "text-action"
  end

  SECTIONS = {
    today: %w[home today/waterings],
    house: %w[house house_tasks tasks plants plants/photos plants/analyses plants/analysis_questions households locations],
    journal: %w[journal]
  }.freeze

  # The web tab bar is shown once signed in with a household (not on the sign-in pages, nor on the first household
  # form), in the browser only: the Android app has native tabs (MainTabs.kt).
  def show_tabs?
    return @show_tabs if defined?(@show_tabs)

    @show_tabs = !hotwire_native_app? && authenticated? && Current.user.present? && policy_scope(Household).exists?
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
  def confirm_data(message, button:, cancel: nil, danger: false)
    {
      turbo_confirm: message,
      confirm_button: button,
      confirm_cancel: cancel,
      confirm_tone: ("danger" if danger)
    }.compact
  end
end
