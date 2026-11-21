# "Réglages": the account, the notifications, the households, signing out. Out of the tabs: rarely visited.
class SettingsController < ApplicationController
  def show
    authorize Current.user, :update?, policy_class: UserPolicy
    @household = current_household
  end
end
