# Membres et invités

> **Statut : proposition, à valider par le propriétaire.** Choix déjà faits par le propriétaire le 27 novembre 2026 :
> invitation par un lien à partager, tous les gestionnaires peuvent inviter, invités ouverts par sujet avec un choix
> « Tout », conception complète avant la série de PR. Remplace l'esquisse `TaskAccess` de `docs/domaine.md`.

Objectif (`docs/produit.md`) : toute la connaissance de la maison est partagée par les membres du foyer. Tant qu'un
foyer n'a qu'un utilisateur, rien n'est partagé : c'est la fonction qui rend l'objectif réel.

Principe repris de la conception précédente : **un champ, un objet ou un écran n'existe que si l'app s'en sert ou si
l'utilisateur va le relire.**

## 1. Les rôles

| Rôle (écran) | Code | Ce qu'il fait |
|---|---|---|
| **Gestionnaire** | `manager` | Tout ce que fait un membre, plus : inviter, changer un rôle, retirer quelqu'un, régler le foyer (nom, adresse). Plusieurs par foyer. |
| **Membre** | `member` | Voit et fait tout : plantes, équipements, tâches, photos, analyses. Ne gère ni le foyer ni ses membres. |
| **Invité** | `guest` | Voit et fait les tâches des sujets qui lui sont ouverts, pendant une période facultative. Ne modifie rien. |

- « Propriétaire » devient **Gestionnaire**, et il peut y en avoir plusieurs : un couple gère le foyer à deux. Le rôle
  `owner` est renommé `manager` en base (migration de données, avec sa spec).
- **Toujours au moins un gestionnaire** : le dernier ne peut ni quitter le foyer, ni être retiré, ni perdre son rôle.
  L'écran le dit au lieu de cacher le bouton.
- Aujourd'hui, `member` peut déjà régler le foyer (`HouseholdPolicy#update?`) : ce droit passe aux gestionnaires.

## 2. Inviter

Depuis **Réglages → Membres du foyer** (gestionnaire) : « Inviter quelqu'un », choix du rôle, puis l'écran du lien.

```
Inviter quelqu'un
  Rôle : (•) Membre   ( ) Gestionnaire   ( ) Invité
  [Créer le lien]

Lien d'invitation, valable 7 jours, pour une seule personne
  https://…/invitations/k3J9…        [Copier] [Partager]
```

- **Le lien** : un jeton aléatoire, à usage unique, valable 7 jours. Seule son empreinte (SHA-256) est en base : une
  fuite de la base ne donne aucun lien valable. Le lien porte le rôle.
- **Partager** ouvre le partage d'Android dans l'app (Web Share API, disponible dans la WebView), **Copier** partout.
  L'app n'envoie rien elle-même : pas d'e-mail, pas d'adresse à saisir.
- **Les invitations en attente** sont listées sous les membres (« Membre, créée par Quentin, expire le 4 déc. »), avec
  « Annuler ». Une invitation expirée disparaît de la liste.
- Le lien ne se réaffiche pas après coup (seule l'empreinte est gardée) : perdu, on l'annule et on en crée un autre.

## 3. Rejoindre

Le lien ouvre la page « Rejoindre Maison » (nom du foyer, rôle, qui invite). Trois cas :

| Situation | Ce que voit la personne |
|---|---|
| Sans compte | Créer son compte : e-mail, mot de passe, confirmation. Elle est connectée et arrive dans le foyer. |
| Avec un compte, non connectée | « J'ai déjà un compte » : connexion, puis retour sur l'invitation et « Rejoindre ». |
| Connectée | « Rejoindre Maison ». Déjà membre : « Vous faites déjà partie de ce foyer », le lien n'est pas consommé. |

- **L'invitation est la seule porte d'inscription** : sans lien valable, pas de création de compte (la page de
  connexion reste sans « S'inscrire »). `accounts:create` reste pour le premier compte.
- Rejoindre **active le foyer rejoint** dans la session.
- Lien expiré, déjà utilisé ou annulé : « Ce lien n'est plus valable, demandez-en un nouveau », sans dire lequel des
  trois (pas d'information à qui teste des liens).
- Le parcours marche dans un navigateur. L'app Android n'étant pas sur le Play Store, un nouveau membre utilise le
  site, ou reçoit l'APK de production à part (voir les points ouverts).

## 4. Gérer les membres

Liste **Membres du foyer** : nom (l'e-mail tant qu'il n'y a pas de nom), rôle, et pour un invité ce qui lui est
ouvert et jusqu'à quand.

- Un gestionnaire **change le rôle** (membre ↔ gestionnaire ; un invité devient membre, ses accès disparaissent) et
  **retire** quelqu'un, avec confirmation. Retirer ne supprime pas le compte : la personne perd l'accès au foyer, son
  nom reste dans le journal.
- Chacun peut **quitter** un foyer (sauf le dernier gestionnaire), depuis « Mes foyers ».
- Un retiré qui avait ce foyer actif retombe sur son foyer suivant, ou sur « Créer un foyer » (déjà le cas, voir
  `docs/domaine.md`, Foyers et comptes).
- **Qui a fait quoi** : le journal ne le montre pas encore, alors que `completed_by` est enregistré. Avec plusieurs
  membres, il affiche « Fait par Léa ». Il faut un **prénom** (`users.name`), demandé à la création du compte par
  invitation et modifiable dans les réglages ; à défaut, la partie de l'e-mail avant `@`.

## 5. Les invités

### Ce qu'on lui ouvre

Sur la fiche de l'invité (gestionnaire) :

```
Ce que Marc peut voir et faire
  [ Tout ouvrir ]
  ☑ Tâches de la maison (poubelles…)
  ☐ Piscine
  ☑ Ficus du salon
  ☑ Monstera de la terrasse
Du [ 20 déc. ] au [ 5 janv. ]   (facultatif)
```

- **Un accès par sujet** : une plante, un équipement, ou « Tâches de la maison » (les tâches sans sujet). Ouvrir un
  sujet ouvre **toutes ses tâches**, présentes et futures.
- **« Tout ouvrir »** : un drapeau sur l'invité, pas une case par sujet. Un sujet ajouté pendant les vacances est donc
  ouvert aussi.
- **La période** (du / au, facultatifs) porte sur l'invité, pas sur chaque sujet : c'est « pendant les vacances ».
  Hors période, l'invité voit « Votre accès à Maison commence le 20 déc. » ou « … s'est terminé le 5 janv. » et ne
  reçoit rien. Prolonger = changer la date.
- Les accès se règlent **après** que l'invité a rejoint : l'invitation ne porte que le rôle. Tant que rien n'est
  ouvert : « Rien ne vous est encore confié dans Maison ».
- Archiver ou supprimer un sujet retire son accès (la ligne d'accès est supprimée avec le sujet).

### Ce qu'il voit et fait

| Écran | Invité |
|---|---|
| Aujourd'hui | Les échéances des tâches ouvertes : Fait, Reporter, annuler |
| Feuille d'une tâche | Comment faire, photos de la tâche, Fait |
| Fiche d'un sujet ouvert | En lecture : « À savoir » d'un équipement, photos, tâches. Pas les analyses d'une plante |
| Maison | La liste des sujets ouverts seulement |
| Journal | Les échéances des tâches ouvertes |
| Réglages | Notifications, Mes foyers ; pas Membres ni Ma maison |

Il ne crée, ne modifie, ne supprime rien (ni tâche, ni sujet, ni photo) et ne lance pas d'analyse.

### Ce qu'il reçoit

Pendant sa période : le **résumé du matin** et les **rappels** des seules tâches ouvertes, comme un membre.

## 6. Modèle

```
Household
  has_many :members (HouseholdMember), :invitations

HouseholdMember
  role (manager | member | guest)       # owner renommé manager
  guest_full_access (bool, false)       # « Tout ouvrir »
  access_starts_on, access_ends_on      # période de l'invité, facultatives
  has_many :guest_accesses

GuestAccess                             # un sujet ouvert à un invité
  household_member (guest), subject (polymorphe : Plant, Equipment, Household = tâches de la maison)
  unique (household_member, subject)

Invitation
  household, created_by (User), role
  token_digest (SHA-256, unique), expires_at (7 jours)
  accepted_by (User), accepted_at, revoked_at

User
  name                                  # prénom affiché dans le journal et la liste des membres
```

- « Tâches de la maison » ouvertes = un `GuestAccess` dont le sujet est le foyer : pas de valeur spéciale.
- **Les règles d'accès vivent dans les policies** (Pundit), à partir d'un query object `VisibleTasksQuery(user,
  household)` : toutes les tâches pour un gestionnaire ou un membre ; pour un invité dans sa période, celles des sujets
  ouverts (ou toutes si `guest_full_access`). Aujourd'hui, le Journal, la Maison, le résumé et les rappels lisent tous
  ce scope : une seule définition de « ce que je vois ».
- Services : `Invitations::Create`, `Invitations::Accept` (crée le compte au besoin, la membership, consomme le lien,
  dans une transaction avec verrou sur l'invitation : deux clics simultanés ne créent qu'une membership),
  `Members::ChangeRole`, `Members::Remove` (garde-fou du dernier gestionnaire, sous verrou du foyer).
- Sécurité : création de compte limitée par `rate_limit` (comme la connexion) ; le jeton se compare par son empreinte ;
  les pages d'invitation ne disent pas si un e-mail a déjà un compte.

## 7. Découpage en PR

Dans une branche d'intégration `membres`, comme la série `domaines` ; le propriétaire teste la fin et merge dans
`main`. Chaque PR : specs (system spec pour chaque parcours), `CI=true bin/ci` vert, revue par un agent.

| PR | Contenu |
|---|---|
| 0 | Cette conception, ADR 0019 (invitation par lien, inscription par invitation, accès invité par sujet), `docs/domaine.md` |
| 1 | Rôle `owner` → `manager` (migration de données), plusieurs gestionnaires, régler le foyer réservé aux gestionnaires ; `users.name` |
| 2 | Membres du foyer (liste), inviter (lien, Copier, Partager), rejoindre avec ou sans compte, invitations en attente et annulation |
| 3 | Changer un rôle, retirer, quitter ; garde-fou du dernier gestionnaire ; « Fait par Léa » dans le journal |
| 4 | Invités : `GuestAccess`, « Tout ouvrir », période ; `VisibleTasksQuery` et policies ; Aujourd'hui, feuille, Journal, Maison, fiches en lecture |
| 5 | Notifications des invités (résumé et rappels des tâches ouvertes, dans la période) ; parcours complet « le voisin pendant les vacances » |

Parcours critiques ajoutés à `docs/tests.md` : inviter puis rejoindre sans compte ; rejoindre avec un compte ;
retirer un membre ; ouvrir un sujet à un invité qui fait la tâche, et ne voit rien d'autre ; accès hors période.

## 8. Points ouverts

1. **L'app Android pour les autres membres** : sans Play Store, il faut leur envoyer l'APK de production (signé,
   mises à jour à la main) ou qu'ils utilisent le site. Un canal de distribution (Play Store en test interne, Firebase
   App Distribution) est un sujet à part, hors de cette série.
2. **Lien ouvert dans l'app** : un lien d'invitation s'ouvre dans le navigateur, pas dans l'app (les App Links
   Android demandent un fichier `assetlinks.json` et la clé de signature). Hors série, sauf avis contraire.
3. **Accès réglés à l'invitation** plutôt qu'après : plus confortable pour le voisin (tout est prêt quand il clique),
   mais l'invitation doit alors porter les accès. Proposé : après, plus simple ; à revoir à l'usage.
