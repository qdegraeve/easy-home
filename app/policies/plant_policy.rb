# Owner and member manage plants (HouseholdRecordPolicy), and archive or restore them.
class PlantPolicy < HouseholdRecordPolicy
  def archive?
    manage?
  end

  def restore?
    manage?
  end
end
