class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :household_members, dependent: :destroy
  has_many :households, through: :household_members
  has_many :push_devices, through: :sessions

  DIGEST_MINUTES = (5 * 60..22 * 60).step(15).to_a.freeze

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(name) { name.squish.presence }

  validates :name, length: { maximum: 50 }
  # Accounts are created from an invitation link (ADR 0019): a password long enough, checked whenever it is set.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :digest_minute, inclusion: { in: DIGEST_MINUTES }
  # What the morning digest lists: every task due, or only the ones that must not be missed (UX review #22).
  enum :digest_scope, { all: "all", critical: "critical" }, prefix: :digest, validate: true

  # Shown to the other members (ADR 0019): the first name, else the start of the email, up to the first dot or
  # underscore ("sam.dupont@…" gives "Sam").
  def display_name
    name || email.split(/[@._]/).first.upcase_first
  end
end
