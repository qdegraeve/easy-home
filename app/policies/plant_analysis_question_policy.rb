# Follow-up questions on an analysis: whoever may accept its proposals (owner and member, finished analysis, plant
# not archived) may ask, and ask a failed question again.
class PlantAnalysisQuestionPolicy < ApplicationPolicy
  def create?
    PlantAnalysisPolicy.new(user, record.analysis).accept?
  end

  def ask_again?
    create? && record.failed?
  end
end
