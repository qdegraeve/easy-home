# Hotwire Native (Android)

> **Statut : à construire** (étapes 2 à 4 de la roadmap). Ce document fixe les intentions ; le compléter au fil de l'implémentation.

## Objectifs

- Une app Android qui affiche l'app Rails dans une webview Hotwire Native, avec quelques éléments natifs.
- Apprendre Hotwire Native et mesurer sa complexité réelle (développement **et** déploiement), en vue d'un autre projet en webview.

## Organisation

- Projet Android dans le dossier `android/` de ce dépôt (proposition : un seul dépôt tant que le projet est personnel).
- Kotlin, Android Studio, bibliothèque `dev.hotwire:core` et `dev.hotwire:navigation-fragments`.
- **Le Kotlin reste de la plomberie** : navigation, notifications, stockage sécurisé, bridge. Toute logique métier vit dans Rails.

## Ce qui est web et ce qui est natif

| Web (Rails, dans la webview) | Natif (Kotlin) |
|---|---|
| Tous les écrans métier : tâches, journal, éléments, foyer, réglages | Coque de navigation (barre, onglets éventuels) |
| Formulaires | Réception des notifications push et bouton d'action « Fait » |
| | Stockage sécurisé du jeton d'API |
| | Bridge components : boutons de barre d'outils, menus, plus tard appareil photo |

## Path configuration

- Fichier JSON **servi par Rails** (ex. `GET /configurations/android_v1.json`), avec une copie embarquée dans l'app en secours.
- Il définit les règles de navigation par motif d'URL : `/new$` et `/edit$` en modal, rafraîchissement après soumission, écrans natifs éventuels.
- Avantage : on modifie la navigation sans republier l'app. Versionner le chemin (`android_v1`) pour ne pas casser les anciennes versions installées.

## Côté Rails

- `hotwire_native_app?` (fourni par `turbo-rails`) pour adapter le rendu : masquer la navigation web, par exemple.
- Pas de dépendance à `hover` ; cibles tactiles d'au moins 44 px ; pas de `target="_blank"`.
- Les bridge components ont une partie Stimulus (`app/javascript/controllers/bridge/`), basée sur `@hotwired/hotwire-native-bridge`.

## Authentification

Deux canaux coexistent :

1. **Webview** : session Rails classique par cookie (générateur d'authentification de Rails 8).
2. **Actions natives** (bouton « Fait » d'une notification, app pas forcément ouverte) : pas d'accès fiable au cookie. On utilise un **jeton d'API par appareil** :
   - émis à la connexion ou à l'enregistrement de l'appareil, et transmis au natif via un bridge component ;
   - stocké côté Android dans `EncryptedSharedPreferences` (ou le Keystore) ;
   - stocké côté Rails sous forme de hash (`Device#api_token_digest`), révocable ;
   - envoyé en `Authorization: Bearer ...` vers un espace `api/v1` restreint (JSON), ex. `POST /api/v1/task_occurrences/:id/completion`.

   Ces endpoints appellent **les mêmes services** que le web (`Tasks::Complete`) et passent par les mêmes policies.

## Notifications push

**Chaîne complète** :

1. Le job récurrent Solid Queue (toutes les minutes) s'exécute.
2. `DueOccurrencesQuery` sélectionne les échéances à notifier.
3. `Reminders::SendDue` envoie les notifications via un adaptateur, vers Firebase Cloud Messaging, puis vers l'appareil.

**Côté serveur** :

- Gem `action_push_native` (37signals) ou `noticed` : à trancher au moment de l'implémentation, avec un ADR.
- Toujours derrière un adaptateur (`PushNotifier`), avec un faux adaptateur en test.
- Messages en priorité haute pour passer le mode Doze.
- Le payload contient l'id de l'échéance et l'URL à ouvrir.

**Côté Android** :

- Permission `POST_NOTIFICATIONS` (Android 13+) demandée au bon moment, pas au premier lancement.
- Un canal de notification par catégorie (rappels, relances).
- Action « Fait » : un `BroadcastReceiver` appelle l'API avec le jeton, sans ouvrir l'app, puis met à jour ou retire la notification.
- Toucher la notification ouvre l'URL de l'échéance dans la webview.

**Configuration** :

- Projet Firebase, `google-services.json` dans l'app (ne pas le versionner s'il est sensible).
- Compte de service Firebase dans les credentials Rails.

**Points de vigilance** : les restrictions d'arrière-plan des constructeurs (économies de batterie) sont à tester sur l'appareil réel.

## Déploiement

- **Rails** : Kamal (`config/deploy.yml`). Il faut une URL HTTPS publique pour l'app mobile et Firebase. Si l'app est auto-hébergée, passer par un tunnel (ex. Cloudflare Tunnel).
- **Android, usage privé** : APK signé installé à la main, ou piste de test interne de la Play Console (compte développeur requis).
- La publication publique impose des contraintes supplémentaires (test fermé obligatoire pour les comptes personnels) : hors périmètre pour l'instant.
- Garder la clé de signature hors du dépôt.

## Journal d'apprentissage

Noter ici ce qui a été plus simple ou plus compliqué que prévu : c'est l'un des objectifs du projet.

- _(vide)_
