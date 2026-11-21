# "Journal": what was done in the household, by whom and when, newest first; a completion can be cancelled from here
# as from the plant page.
class JournalController < ApplicationController
  DAYS = 60

  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    @entries = policy_scope(TaskOccurrence).done.joins(:task).where(tasks: { household_id: @household.id })
      .where(completed_at: (DAYS - 1).days.ago.beginning_of_day..).includes(:completed_by, task: :subject)
      .order(completed_at: :desc, id: :desc)
      .group_by { |occurrence| occurrence.completed_at.to_date }
  end
end
