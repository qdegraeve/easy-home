# 0014. Bridge components : boutons et menus natifs pilotés par les pages

- Statut : acceptée
- Date : 2026-11-22

## Contexte

La revue UX (changements #9 et #10) veut l'action principale d'une page (« + ») et ses actions secondaires (Modifier,
Archiver, Supprimer) dans la barre native du haut de l'app Android, comme dans une app native. La page web reste la
source : elle sait quelles actions existent, avec quels droits et quelles confirmations.

## Décision

- **Bibliothèque `@hotwired/hotwire-native-bridge`** (1.2.2, MIT, maintenue par l'équipe Hotwire) côté web : elle
  fournit `BridgeComponent` (un contrôleur Stimulus qui échange des messages avec l'app) et marque `<html>` avec les
  composants que l'app supporte. C'est le pendant officiel de Hotwire Native Android, déjà utilisé par la coque.
- **Deux composants** (puis `push`, ADR 0012) : `button` (un ou deux boutons flottants avec libellé, en bas à droite) et `menu` (les entrées
  du menu ⋮ de la barre du haut). La page déclare
  ses éléments par des attributs ; un appui côté app renvoie un message, et la page clique son propre élément : les
  confirmations, autorisations et redirections restent celles de Rails.
- **Côté Kotlin**, les messages sont lus avec `org.json` (inclus dans Android) : pas de plugin de sérialisation.
- Les éléments web pris en charge sont masqués dans l'app par une règle CSS ; dans le navigateur, rien ne change.

## Alternatives écartées

- **Écrire le pont à la main** (`window.HotwireNative`, messages) : recopie de la bibliothèque officielle, sans gain.
- **Menu natif codé en dur dans l'app** (comme l'icône Réglages) : il faudrait dupliquer en Kotlin les règles de
  chaque page (actions possibles, plante archivée, droits), et republier l'app à chaque changement.
- **« + » dans la barre du haut** (prévu par la revue UX) : essayé, puis remplacé par le bouton flottant à la demande
  du propriétaire ; la barre du haut gardait trop d'icônes (+, Réglages, ⋮).

## Conséquences

- Une dépendance npm de plus, suivie par Dependabot.
- Une nouvelle action native = des attributs dans une vue, sans republier l'app (sauf une nouvelle icône).