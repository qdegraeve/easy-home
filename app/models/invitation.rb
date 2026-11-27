# The link that gives a reserved place of a household to a person (ADR 0019): single use, valid 7 days, sent to an
# e-mail address that only can take it (ADR 0020). The token goes in the e-mail; only its SHA-256 digest is stored, so a
# copy of the database opens nothing.
class Invitation < ApplicationRecord
  VALIDITY = 7.days

  belongs_to :household_member
  belongs_to :created_by, class_name: "User", optional: true
  has_one :household, through: :household_member

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :create

  # The token of the link, only on the instance that generated it.
  attr_reader :token

  scope :usable, -> { where(accepted_at: nil).where(expires_at: Time.current..) }

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  # The usable invitation of this token, if any: expired, used and unknown links look the same.
  def self.find_usable(token)
    usable.find_by(token_digest: digest(token)) if token.present?
  end

  # A new token (and validity) for this invitation: the previous link stops working.
  def renew_token
    @token = SecureRandom.urlsafe_base64(24)
    self.token_digest = self.class.digest(@token)
    self.expires_at = VALIDITY.from_now
    self
  end

  def usable?
    accepted_at.nil? && expires_at.future?
  end
end
