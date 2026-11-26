# 0018. Envoi des e-mails : relais SMTP de Brevo

- Statut : acceptée
- Date : 2026-11-26

## Contexte

La production doit envoyer des e-mails : aujourd'hui le lien « mot de passe oublié », demain les invitations des
membres du foyer, à n'importe quelle adresse. Le serveur de la maison n'a aucune réputation d'expéditeur : envoyés
directement, les e-mails finiraient en spam ou seraient refusés. Volume : quelques e-mails par mois. Contrainte : coût
nul.

## Décision

- Les e-mails passent par le **relais SMTP de Brevo** (offre gratuite, environ 300 e-mails par jour, données en UE).
  Rails parle SMTP sans gem supplémentaire (`config/environments/production.rb`).
- Identifiants (`SMTP_USERNAME`, `SMTP_PASSWORD`) dans le gestionnaire de secrets, transmis par Kamal comme les autres
  secrets, et non dans les credentials Rails : un seul endroit pour les secrets de production.
- L'expéditeur (`MAIL_FROM`) est sur un vrai domaine : il vit dans `config/application.yml`, hors du dépôt, et passe
  par `env.clear`. Il est lu à chaque e-mail ; sans lui (dev, tests, build de l'image), une adresse `example.com`.
- Le domaine d'expédition est vérifié par **configuration DNS manuelle** (TXT de vérification, DKIM, DMARC), jamais par
  délégation du sous-domaine (enregistrements NS) : une délégation masque les enregistrements existants du même nom,
  dont celui de l'app. Le domaine d'expédition ne porte pas de CNAME (incompatible avec le TXT de vérification) :
  domaine racine ou sous-domaine dédié aux e-mails.
- Les erreurs d'envoi sont levées : un e-mail en échec reste visible comme job en échec dans Solid Queue.

## Alternatives écartées

- **Cloudflare Email Service** : le domaine y est déjà, mais l'envoi gratuit ne vise que des adresses vérifiées du
  compte (les invitations iraient à n'importe qui) et le service est en bêta.
- **Resend** : bonne API, offre gratuite plus serrée (environ 100 e-mails par jour), entreprise hors UE.
- **Envoi direct depuis le serveur** : délivrabilité mauvaise, port 25 souvent bloqué par les fournisseurs d'accès.

## Conséquences

- Changer de fournisseur ne touche que `SMTP_ADDRESS`, les identifiants et les enregistrements DNS.
- Si l'offre gratuite disparaît ou ne suffit plus, nouvel ADR.