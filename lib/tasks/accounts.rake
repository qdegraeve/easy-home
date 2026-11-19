require "io/console"

namespace :accounts do
  desc "Crée un compte et son foyer : bin/rails accounts:create EMAIL=moi@example.com HOUSEHOLD=\"Ma maison\""
  task create: :environment do
    email_address = ENV.fetch("EMAIL") { abort "EMAIL manquant" }
    household_name = ENV.fetch("HOUSEHOLD", "Ma maison").dup.force_encoding(Encoding::UTF_8)
    password = $stdin.tty? ? IO.console.getpass("Mot de passe : ") : $stdin.gets.to_s.chomp

    case Accounts::Create.new.call(email_address:, password:, household_name:)
    in Dry::Monads::Success(user)
      puts "Compte créé : #{user.email_address} (foyer « #{household_name} »)"
    in Dry::Monads::Failure[ :invalid, record ]
      abort "Échec : #{record.errors.full_messages.to_sentence}"
    end
  end
end
