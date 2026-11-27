# "Mon compte": the first name shown to the other members of the household (ADR 0019).
class AccountsController < ApplicationController
  def edit
    authorize Current.user, policy_class: UserPolicy
    @user = Current.user
  end

  def update
    authorize Current.user, policy_class: UserPolicy
    @user = Current.user

    if @user.update(params.expect(user: [ :name ]))
      redirect_to settings_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end
end
