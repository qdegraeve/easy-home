# Recurring (config/recurring.yml): an invitation left to expire frees its reserved place (ADR 0019).
class PurgeExpiredInvitationsJob < ApplicationJob
  queue_as :default

  def perform
    Invitations::PurgeExpired.new.call
  end
end
