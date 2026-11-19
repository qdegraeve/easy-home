require "io/console"

namespace :accounts do
  desc "Crée un compte et son foyer : bin/rails accounts:create EMAIL=moi@example.com HOUSEHOLD=\"Ma maison\""
  task create: :environment do
    email_address = ENV.fetch("EMAIL") { abort "EMAIL manquant" }
    household_name = ENV.fetch("HOUSEHOLD", "Ma maison").dup.force_encoding(Encoding::UTF_8)
    if $stdin.tty?
      password = IO.console.getpass("Mot de passe : ")
      abort "Les mots de passe ne correspondent pas" unless IO.console.getpass("Confirmation : ") == password
    else
      password = $stdin.gets.to_s.chomp
    end

    case Accounts::Create.new.call(email_address:, password:, household_name:)
    in Dry::Monads::Success(user)
      puts "Compte créé : #{user.email_address} (foyer « #{household_name} »)"
    in Dry::Monads::Failure[ :invalid, record ]
      abort "Échec : #{record.errors.full_messages.to_sentence}"
    end
  end
end
