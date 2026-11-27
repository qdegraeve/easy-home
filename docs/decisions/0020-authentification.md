# 0020. Authentification : générateur Rails, invitation par e-mail, mots de passe longs

- Statut : acceptée
- Date : 2026-11-27

## Contexte

L'authentification vient du générateur de Rails 8 (`has_secure_password`, modèle `Session`, réinitialisation du mot
de passe, `rate_limit`), sans ADR jusqu'ici. Avec les membres (ADR 0019), des comptes se créent depuis une invitation :
la première version donnait un lien que le gestionnaire envoyait lui-même, n'importe qui l'ayant entre les mains
pouvait créer un compte, et le mot de passe demandait 8 caractères.

## Décision

- **On garde le générateur de Rails**, pas Devise : une centaine de lignes dans l'app, lisibles et testées ; les
  sessions sont en base, et un téléphone (notifications, ADR 0012) est rattaché à sa session. Aucun module de Devise
  ne manque : la confirmation est couverte par l'invitation, la connexion est limitée en nombre d'essais.
- **L'invitation part par e-mail** à l'adresse saisie par le gestionnaire, et seule cette adresse peut la prendre :
  le compte créé porte cette adresse, non modifiable, et un compte connecté avec une autre adresse est refusé. Le clic
  sur le lien reçu prouve l'adresse : **pas d'e-mail de confirmation**, le compte sert tout de suite. L'e-mail est
  envoyé sans job, pour que le jeton ne soit stocké nulle part (seule son empreinte est en base).
- **Mots de passe** (NIST SP 800-63B-4, 2025) : 15 caractères au moins, pas de règle de composition (majuscule,
  caractère spécial), refus de ce qui se devine (peu de caractères différents, morceau répété, suite du clavier ou de
  l'alphabet, nom de l'app, début de l'e-mail : `PasswordPolicy`, sans appel externe). La règle vaut à chaque nouveau
  mot de passe ; les comptes existants s'y plient au prochain changement.
- **Hors production**, `passwordpassword` est accepté (`config.x.allowed_passwords`, dev et test) : facile à taper en
  développement et dans les specs.

## Alternatives écartées

- **Devise** : beaucoup de code et de configuration pour des besoins déjà couverts ; ses modules s'ajoutent à
  Warden, qu'il faut ensuite surcharger.
- **Lien à partager** (première version de l'ADR 0019) : il circule hors de l'app, et quiconque le reçoit crée un
  compte.
- **E-mail de confirmation après l'inscription** : redondant, le lien arrive déjà dans la boîte de l'adresse.
- **Règles de composition** : elles poussent vers « Motdepasse1! » sans rendre le mot de passe plus solide.
- **Vérification des mots de passe ayant fuité par un service externe** (Have I Been Pwned) : un appel réseau à
  chaque mot de passe ; à revoir si les règles locales ne suffisent pas.

## Conséquences

- Inviter dépend de Brevo : un e-mail qui ne part pas est dit au gestionnaire, et rien n'est réservé.
- Le composant natif `share` (feuille de partage d'Android) est retiré : il ne servait qu'au lien à partager.
- Un compte sans second facteur reste à un seul facteur : d'où les 15 caractères.
