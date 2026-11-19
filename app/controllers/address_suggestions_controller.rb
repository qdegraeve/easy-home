class AddressSuggestionsController < ApplicationController
  MIN_LENGTH = 3
  MAX_LENGTH = 200

  def index
    authorize :address_suggestion, :index?

    query = params[:q].to_s.strip.first(MAX_LENGTH)
    @suggestions = query.length >= MIN_LENGTH ? Geo.geocoder.suggest(query) : []
    render layout: false
  end
end
