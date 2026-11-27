# "Réglages": the account, the members, the notifications, the households, signing out. Out of the tabs: rarely
# visited.
class SettingsController < ApplicationController
  def show
    authorize Current.user, :update?, policy_class: UserPolicy
    household = current_household
    @members_visible = household && policy(HouseholdMember.new(household:)).index?
  end
end
