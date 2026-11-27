# The guest access fields of a form (members/_guest_access): "Tout ouvrir", the period, the subjects opened.
module GuestAccessParams
  def self.from(params)
    params.fetch(:guest_access, {}).permit(:full_access, :starts_on, :ends_on, subjects: []).to_h.symbolize_keys
  end
end
