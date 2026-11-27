# The rules of a password (ADR 0020, after NIST SP 800-63B-4): long rather than complicated. At least 15 characters,
# no composition rule (capital letter, symbol), and none easy to guess: too few different characters, a repeated
# chunk, a keyboard or alphabetical run, or the e-mail or the app's name in it. Pure Ruby: User calls it.
#
#   PasswordPolicy.new(allowed: ["passwordpassword"]).errors("aaaaaaaaaaaaaaaa", email: "lea@example.com")
#   # => [:guessable]
class PasswordPolicy
  MIN_LENGTH = 15
  RUNS = %w[
    0123456789012345678901234567890 abcdefghijklmnopqrstuvwxyz qwertyuiopasdfghjklzxcvbnm azertyuiopqsdfghjklmwxcvbn
  ].freeze
  NAMES = %w[easyhome motdepasse password].freeze

  # allowed: passwords accepted whatever the rules (outside production only, see config.x.allowed_passwords).
  def initialize(allowed: [])
    @allowed = allowed
  end

  def errors(password, email: nil)
    return [] if @allowed.include?(password)
    return [ :too_short ] if password.to_s.length < MIN_LENGTH

    guessable?(password.downcase.gsub(/[^[:alnum:]]/, ""), email) ? [ :guessable ] : []
  end

  private

  def guessable?(text, email)
    text.chars.uniq.size < 6 || repeated?(text) || run?(text) || names?(text, email)
  end

  # "passwordpassword", "abcabcabc…": one chunk over and over.
  def repeated?(text)
    (1..text.length / 2).any? { |size| text == text[0, size] * (text.length / size) && (text.length % size).zero? }
  end

  def run?(text)
    RUNS.any? { |run| (run + run.reverse).include?(text) }
  end

  # The name of the app, the word "password", or the start of the e-mail, as most of the password.
  def names?(text, email)
    local = email.to_s.split("@").first.to_s.downcase.gsub(/[^[:alnum:]]/, "")
    words = NAMES + (local.length >= 4 ? [ local ] : [])
    words.any? { |word| text.include?(word) && text.length - word.length < 8 }
  end
end
