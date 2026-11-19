class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true

  # Un seul foyer par utilisateur tant que les invitations n'existent pas.
  def household
    user&.households&.first
  end
end
