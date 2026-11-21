module ApplicationHelper
  # Sets the page <title>, which the Hotwire Native shell shows in its top bar, and returns the text for the <h1>.
  def page_title(text)
    content_for(:title, text)
    text
  end

  # "← …" link at the top of a page, for the browser only: in the Android app, the native top bar and the system
  # back already go back, and a web link would push a new screen instead of going back.
  def back_link_to(text, url)
    link_to(text, url, class: "text-sm text-stone-500 underline") unless hotwire_native_app?
  end

  # Form data for a confirmed action: the message, the label of the confirm button (the action itself, not
  # "confirm"), and the danger tone for destructive actions. Read by app/javascript/lib/confirm_dialog.js.
  def confirm_data(message, button:, danger: false)
    { turbo_confirm: message, confirm_button: button, confirm_tone: ("danger" if danger) }.compact
  end
end
