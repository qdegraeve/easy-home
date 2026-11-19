require "io/console"

namespace :accounts do
  desc "Crée un compte (le foyer se crée ensuite dans l'app) : bin/rails accounts:create EMAIL=moi@example.com"
  task create: :environment do
    email_address = ENV.fetch("EMAIL") { abort "EMAIL manquant" }

    if $stdin.tty?
      password = IO.console.getpass("Mot de passe : ")
      abort "Les mots de passe ne correspondent pas" unless IO.console.getpass("Confirmation : ") == password
    else
      password = $stdin.gets.to_s.chomp
    end

    user = User.new(email_address:, password:)
    abort "Échec : #{user.errors.full_messages.to_sentence}" unless user.save

    puts "Compte créé : #{user.email_address}"
  end
end
