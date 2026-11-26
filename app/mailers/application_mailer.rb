# The sender comes from MAIL_FROM in production (a real domain, kept out of the repository; ADR 0018). Read for each
# email, so it never ends up frozen in the image built without it.
class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM = "Easy Home <no-reply@example.com>".freeze

  default from: -> { ENV.fetch("MAIL_FROM", DEFAULT_FROM) }
  layout "mailer"
end
