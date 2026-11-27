# "Mon compte": the first name shown to the other members of the household, and deleting the account (ADR 0019).
class AccountsController < ApplicationController
  def edit
    authorize Current.user, policy_class: UserPolicy
    @user = Current.user
    load_deletion
  end

  def update
    authorize Current.user, policy_class: UserPolicy
    @user = Current.user

    if @user.update(params.expect(user: [ :name ]))
      redirect_to settings_path, notice: t(".success")
    else
      load_deletion
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize Current.user, policy_class: UserPolicy
    result = Accounts::Destroy.new.call(user: Current.user, password: params[:password])

    if result.success?
      cookies.delete(:session_id)
      redirect_to new_session_path, notice: t(".success"), status: :see_other
    else
      redirect_to edit_account_path, alert: t(".#{result.failure.first}"), status: :see_other
    end
  end

  private

  # Said before confirming: the households that go with the account, and those to hand over first.
  def load_deletion
    @households_alone = Accounts::Destroy.households_alone(Current.user).order(:name).to_a
    @households_to_hand_over = Accounts::Destroy.households_to_hand_over(Current.user).order(:name).to_a
  end
end
