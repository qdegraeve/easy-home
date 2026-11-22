class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :household_members, dependent: :destroy
  has_many :households, through: :household_members
  has_many :push_devices, through: :sessions

  DIGEST_MINUTES = (5 * 60..22 * 60).step(15).to_a.freeze

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :digest_minute, inclusion: { in: DIGEST_MINUTES }
  # What the morning digest lists: every task due, or only the ones that must not be missed (UX review #22).
  enum :digest_scope, { all: "all", critical: "critical" }, prefix: :digest, validate: true
end
