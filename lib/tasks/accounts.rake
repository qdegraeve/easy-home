require "io/console"

namespace :accounts do
  desc "Creates an account (the household is then created in the app): bin/rails accounts:create EMAIL=me@example.com"
  task create: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is missing" }

    if $stdin.tty?
      password = IO.console.getpass("Password: ")
      abort "Passwords do not match" unless IO.console.getpass("Confirmation: ") == password
    else
      password = $stdin.gets.to_s.chomp
    end

    user = User.new(email:, password:)
    abort "Failed: #{user.errors.full_messages.to_sentence}" unless user.save

    puts "Account created: #{user.email}"
  end
end
