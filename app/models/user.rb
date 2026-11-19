class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :household_members, dependent: :destroy
  has_many :households, through: :household_members

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
