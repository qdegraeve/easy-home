class AddressSuggestionPolicy < ApplicationPolicy
  def index?
    user.present?
  end
end
