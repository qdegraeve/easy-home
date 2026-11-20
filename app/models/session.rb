class Session < ApplicationRecord
  belongs_to :user
  # A phone registers for push notifications within a signed-in session: signing out on the phone removes it, so a
  # signed-out phone never receives anything (ADR 0012).
  has_many :push_devices, as: :owner, class_name: "ApplicationPushDevice", dependent: :destroy
end
