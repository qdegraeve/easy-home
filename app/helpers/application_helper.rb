module ApplicationHelper
  # Sets the page <title>, which the Hotwire Native shell shows in its top bar, and returns the text for the <h1>.
  def page_title(text)
    content_for(:title, text)
    text
  end

  # Form data for a confirmed action: the message, the label of the confirm button (the action itself, not
  # "confirm"), and the danger tone for destructive actions. Read by app/javascript/lib/confirm_dialog.js.
  def confirm_data(message, button:, danger: false)
    { turbo_confirm: message, confirm_button: button, confirm_tone: ("danger" if danger) }.compact
  end
end
