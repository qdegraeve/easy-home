# Hotwire Native (Android)

> **Statut : coque en place** (étape 3 de la roadmap) : l'app Android affiche l'app Rails, avec la navigation par
> path configuration ; la prise de photo directe fonctionne. À venir : notifications push, déploiement.
> Explication pédagogique de chaque morceau : `docs/android-coque.md`.

## Objectifs

- Une app Android qui affiche l'app Rails dans une webview Hotwire Native, avec quelques éléments natifs.
- Apprendre Hotwire Native et mesurer sa complexité réelle (développement **et** déploiement), en vue d'un autre projet en webview.

## Organisation

- Projet Android dans le dossier `android/` de ce dépôt (un seul dépôt tant que le projet est personnel).
- Kotlin, Android Studio, bibliothèques `dev.hotwire:core` et `dev.hotwire:navigation-fragments` (1.4.1).
- Identifiant de l'app : `app.easyhome.android` en production, `app.easyhome.android.debug` pour la version de test
  (« Easy Home (dev) », icône grise) : les deux s'installent côte à côte. Neutre, aucun vrai domaine.
- Build : Android Gradle Plugin 9.4 (Kotlin intégré), Gradle 9.9 (wrapper versionné), compileSdk et targetSdk 37,
  minSdk 28, Java 17. La CI construit l'APK de debug (job « Android ») ; Dependabot suit les dépendances Gradle.
- Code : `EasyHomeApplication` (configuration Hotwire, chargement de la path configuration), `MainActivity` et
  `MainTabs` (trois onglets natifs, un navigateur chacun ; voir `docs/android-coque.md`).
- **Le Kotlin reste de la plomberie** : navigation, notifications, stockage sécurisé, bridge. Toute logique métier vit dans Rails.

## Ce qui est web et ce qui est natif

| Web (Rails, dans la webview) | Natif (Kotlin) |
|---|---|
| Tous les écrans métier : tâches, journal, éléments, foyer, réglages | Coque de navigation (barre, onglets éventuels) |
| Formulaires | Réception des notifications push et bouton d'action « Fait » |
| | Stockage sécurisé du jeton d'API |
| | Bridge components : boutons de barre d'outils, menus, plus tard appareil photo |

## Path configuration

- Fichier JSON **servi par Rails** (`GET /configurations/android_v1`, source `config/hotwire/android_v1.json`), avec
  une copie embarquée dans l'app en secours (`android/app/src/main/assets/json/path-configuration.json`). Une spec
  vérifie que les deux sont identiques.
- Ordre de chargement : la copie embarquée, puis la version en cache, puis celle du serveur, téléchargée en arrière-plan
  et mise en cache.
- Les motifs sont des expressions régulières cherchées dans le chemin **et la query string** (`/plants/new?x=1`) :
  on termine donc un chemin par `($|\?)` plutôt que par `$`.
- Règles actuelles (la dernière règle qui correspond l'emporte) :
  - tout : écran web normal, tirer pour rafraîchir ;
  - chemins finissant par `/new` ou `/edit` : formulaire en modal plein écran, sans tirer pour rafraîchir ;
  - `/`, `/session/new`, `/passwords/new` : remplacent toute la pile (`replace_root`). Sans cette règle, la connexion
    s'ouvrait en modal (elle finit par `/new`) et l'app restait figée après la connexion.
- Avantage : on modifie la navigation sans republier l'app. Le chemin est versionné (`android_v1`) pour ne pas casser
  les anciennes versions installées.

## Développer sur un vrai téléphone

1. Sur le téléphone : options pour les développeurs, puis « Débogage USB » ; brancher au Mac et accepter.
2. Sur le Mac : `bin/dev`, puis `adb reverse tcp:3000 tcp:3000` (à refaire à chaque branchement). Le téléphone joint
   ainsi le serveur du Mac par le câble, sur `http://localhost:3000` : aucune adresse IP dans le dépôt, rien d'ouvert
   sur le Wi-Fi. Le http en clair n'est autorisé qu'en debug et que pour `localhost`
   (`android/app/src/debug/res/xml/network_security_config.xml`).
3. Construire et installer : `cd android && ./gradlew installDebug` (ou depuis Android Studio).
4. Journaux : `adb logcat --pid=$(adb shell pidof app.easyhome.android.debug)` ; la webview se débogue depuis Chrome
   (`chrome://inspect`).

`android/local.properties` (jamais versionné) contient `sdk.dir` et, au besoin, `easyhome.baseUrl` pour viser un autre
serveur, sans `/` final. En debug, le http en clair n'est permis que vers `localhost` : un autre serveur doit être en
https.

### Tester hors de la maison (tunnel)

Sans câble, le téléphone joint le Mac par un tunnel rapide Cloudflare (`cloudflared`, sans compte) :

1. `bin/dev` tourne (assets, jobs) ; dans un autre terminal, `bin/tunnel`. Il lance un second serveur sur le port 3001
   avec `DEV_TUNNEL=1` et affiche une adresse `https://….trycloudflare.com`, aléatoire, qui change à chaque lancement.
   Le Mac reste éveillé (`caffeinate`) jusqu'à Ctrl-C, qui arrête tout.
2. Mettre cette adresse dans `android/local.properties` (`easyhome.baseUrl=…`), puis `./gradlew installDebug`.
3. Au retour : retirer la ligne, réinstaller, `adb reverse tcp:3000 tcp:3000`.

L'adresse est publique : le mot de passe reste exigé, et avec `DEV_TUNNEL` le serveur n'accepte que les hôtes
`trycloudflare.com` et ne montre jamais la page d'erreur détaillée (sa console web serait une console Ruby sur le Mac,
ouverte à Internet). L'adresse ne va jamais dans le dépôt.

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

Décision : ADR 0012 (résumé du matin, gem `action_push_native`, appareil rattaché à la session).

**Chaîne complète** :

1. `SendDigestsJob`, récurrent toutes les 5 minutes, s'exécute.
2. `Notifications::SendDigests` retient les utilisateurs dont l'heure est passée ; `DueOccurrencesQuery` sélectionne
   leurs échéances du jour et en retard.
3. `Notifications::SendDigest` envoie une notification `ApplicationPushNotification` à chaque téléphone, via Firebase
   Cloud Messaging.

**Côté serveur** :

- Gem `action_push_native` ; envoi désactivé en test par la gem, les specs vérifient les jobs mis en file.
- Messages en priorité haute (défaut de la gem) pour passer le mode Doze.
- Le payload contient le chemin à ouvrir (`data.path`, l'accueil pour le résumé).
- Enregistrement : `POST /push_devices` (jeton Firebase), appelé dans la session de l'utilisateur ; l'appareil
  appartient à cette session.
- Réglages : page « Notifications » (🔔 dans l'en-tête), avec un bouton « M'envoyer une notification de test ».

**Côté Android** :

- Permission `POST_NOTIFICATIONS` (Android 13+) demandée depuis la page Notifications, sur un geste de l'utilisateur,
  jamais au premier lancement (bridge component `push`, `PushComponent`).
- Enregistrement : la page envoie le jeton Firebase à `POST /push_devices` ; chaque page de l'app le redonne et ne le
  poste que s'il manque à la session (reconnexion, jeton renouvelé).
- Un canal « Rappels » (`reminders`) ; Firebase affiche la notification en arrière-plan, `EasyHomeMessagingService`
  au premier plan.
- À venir, action « Fait » : un `BroadcastReceiver` appelle l'API avec le jeton, sans ouvrir l'app, puis met à jour ou
  retire la notification.
- Toucher la notification ouvre son `data.path` dans l'onglet Aujourd'hui.

**Configuration** :

- Projet Firebase avec deux apps Android (`app.easyhome.android` et `app.easyhome.android.debug`) ; leur
  `google-services.json` dans `android/app/`, jamais versionné. Sans lui, le plugin n'est pas appliqué : l'app se
  construit sans Firebase (CI).
- Compte de service Firebase dans les credentials Rails (`action_push_native.fcm`, `encryption_key` = le JSON entier,
  `project_id`), de production et de développement.

**Points de vigilance** : les restrictions d'arrière-plan des constructeurs (économies de batterie) sont à tester sur l'appareil réel.

## Déploiement

- **Rails** : Kamal (`config/deploy.yml`). Il faut une URL HTTPS publique pour l'app mobile et Firebase. Si l'app est auto-hébergée, passer par un tunnel (ex. Cloudflare Tunnel).
- **Android, usage privé** : APK de production signé, installé à la main (voir « Version de production » dans
  `docs/android-coque.md`). Piste de test interne de la Play Console possible plus tard (compte développeur requis).
- La publication publique impose des contraintes supplémentaires (test fermé obligatoire pour les comptes personnels) : hors périmètre pour l'instant.
- La clé de signature et ses mots de passe restent hors du dépôt (`android/local.properties`, copie de secours dans
  le gestionnaire de secrets). La perdre oblige à désinstaller l'app pour la mettre à jour.

## Journal d'apprentissage

Noter ici ce qui a été plus simple ou plus compliqué que prévu : c'est l'un des objectifs du projet.

- **Mise en place (novembre 2026)** : rien n'était installé sur le Mac (ni Java, ni SDK). Android Studio par Homebrew
  apporte un JDK (JetBrains Runtime 25) ; le SDK s'installe ensuite avec `sdkmanager`. Compter environ une heure.
- **Plus simple que prévu** : la coque tient en deux classes Kotlin et un layout. Connexion par cookie, formulaires,
  redirections et rafraîchissements Turbo marchent sans rien toucher côté Rails.
- **Piège** : les motifs de la path configuration s'appliquent aussi aux écrans d'authentification. `/session/new`
  ouvert en modal a figé l'app après la connexion (la modal se ferme sur une page qui n'existe plus).
- **`adb reverse`** évite d'exposer le serveur de dev sur le réseau et de mettre une IP dans le code.
- **Photo directe gratuite** : le sélecteur de fichiers de Hotwire Native propose l'appareil photo ; le champ
  `accept="image/*"` existant suffit, sans bridge ni permission à déclarer.
- **À revoir** : transitions entre écrans et navigation jugées peu intuitives au premier essai (barre native avec
  « Easy Home » partout, en-tête web en double, liens « ← retour » web en plus du retour Android).
