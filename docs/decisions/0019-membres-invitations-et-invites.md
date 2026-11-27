# 0019. Membres, invitation par lien et invités par sujet

- Statut : acceptée
- Date : 2026-11-27

## Contexte

L'objectif d'Easy Home est que la connaissance de la maison soit partagée par les membres du foyer
(`docs/produit.md`). Or un foyer n'a qu'un utilisateur : aucun écran n'ajoute quelqu'un, et il n'y a pas
d'inscription publique (les comptes se créent en console). Il faut aussi confier quelques tâches à un invité (le
voisin pendant les vacances) sans lui ouvrir toute la maison. Publier l'app sur les stores impose enfin de pouvoir
supprimer son compte. Conception détaillée : `docs/conception/membres-et-invites.md`.

## Décision

- **Trois rôles** : gestionnaire (`manager`, l'ancien `owner`, plusieurs par foyer), membre, invité. Gérer le foyer et
  ses membres est réservé aux gestionnaires ; il en reste toujours au moins un.
- **Invitation par un lien** (envoyé par e-mail à une adresse, depuis l'ADR 0020) que le gestionnaire partageait
  lui-même : jeton aléatoire, usage unique, 7 jours, seule son
  empreinte SHA-256 en base. L'app n'envoie pas d'e-mail.
- **L'invitation est la seule porte d'inscription** : sans lien valable, pas de création de compte.
- **Inviter réserve une place** : un `HouseholdMember` sans utilisateur, avec son rôle et, pour un invité, ses accès.
  Accepter attache l'utilisateur à cette place ; une place sans utilisateur ne donne aucun droit.
- **Un invité est ouvert par sujet** (`GuestAccess` : une plante, un équipement, ou le foyer pour les tâches de la
  maison) ou à tout (`guest_full_access`), avec une période facultative portée par sa place. Il voit et fait les
  tâches ouvertes, sans rien modifier.
- **Une seule définition de « ce que je vois »** : un query object des tâches visibles, lu par les policies, les
  écrans, le résumé et les rappels.
- **Supprimer son compte**, dans l'app et sur le web ; le journal garde les échéances sans le nom.

## Alternatives écartées

- **Invitation par e-mail** (Brevo est en place, ADR 0018) : il faut saisir l'adresse, l'e-mail peut arriver en spam,
  et un lien envoyé par message suffit pour un foyer.
- **Accès invité par tâche** (`TaskAccess`, l'esquisse d'origine) : cocher chaque tâche est fastidieux, et une tâche
  ajoutée pendant les vacances ne serait pas ouverte.
- **Accès invité réglé après l'acceptation** : l'invité arriverait sur un foyer vide et le gestionnaire devrait
  revenir ; la place réservée évite de recopier les accès d'une invitation vers un membre.
- **Inscription publique** : l'app sert un foyer, pas un public.

## Conséquences

- Migration de données : le rôle `owner` devient `manager` ; `household_members.user_id` devient nullable.
- Les droits existants changent : un `member` ne règle plus le foyer.
- Le journal affiche qui a fait quoi, ce qui demande un prénom (`users.name`).
- Un nouveau membre utilise le site tant que les apps ne sont pas distribuées par les stores (sujet à part).
