# La coque Android, expliquée

Ce document explique, morceau par morceau, comment fonctionne l'app Android d'Easy Home et pourquoi chaque fichier
existe. Il est écrit pour un développeur Rails qui découvre Android et Hotwire Native : les comparaisons avec Rails sont
là pour donner des repères, pas pour être exactes au mot près.

Les décisions et la feuille de route restent dans `docs/hotwire-native.md` ; ici, on explique.

## 1. L'idée en une image

```
┌──────────────── Téléphone ────────────────┐            ┌──────── Mac (ou serveur) ────────┐
│  App Android « Easy Home »                │            │                                  │
│  ┌─────────────────────────────────────┐  │            │  Rails (bin/dev, port 3000)      │
│  │ Barre native (titre, flèche retour) │  │            │                                  │
│  ├─────────────────────────────────────┤  │   HTTP     │  - pages HTML habituelles        │
│  │                                     │  │ ─────────► │  - Turbo, Stimulus               │
│  │  WebView : l'app Rails, telle que   │  │ ◄───────── │  - /configurations/android_v1    │
│  │  dans Chrome                        │  │            │    (règles de navigation)        │
│  │                                     │  │            │                                  │
│  └─────────────────────────────────────┘  │            └──────────────────────────────────┘
└───────────────────────────────────────────┘
```

- L'app Android n'a **aucun écran métier**. Tous les écrans (plantes, tâches, analyses) sont les pages Rails.
- Une **WebView** est un mini-Chrome intégré dans une app. Elle affiche les pages Rails.
- **Hotwire Native** est la bibliothèque qui fait passer cette WebView pour une app native. Chaque page devient un
  « écran » Android, avec une vraie barre en haut, la flèche retour du téléphone, des transitions et des modals.
- Conséquence pratique : **on modifie l'app en déployant Rails**. On ne republie l'app Android que pour changer la
  coque elle-même (notifications, nouveaux composants natifs…).

## 2. Les outils, avec leurs équivalents Rails

| Outil Android | Rôle | Équivalent approximatif côté Rails |
|---|---|---|
| **Kotlin** | Le langage de l'app (moderne, remplace Java) | Ruby |
| **JDK** (Java) | Fait tourner Gradle et le compilateur Kotlin | L'interpréteur `ruby` |
| **Android SDK** | Bibliothèques et outils pour une version d'Android (ici 37) | Les en-têtes et outils système |
| **Gradle** | Construit l'app : télécharge les dépendances, compile, assemble l'APK | Bundler + Rake |
| **AGP** (Android Gradle Plugin) | Le plugin Gradle qui sait construire une app Android | Une gem comme `railties` |
| **Wrapper Gradle** (`gradlew`) | Script qui télécharge et utilise **la** version de Gradle du projet | `bin/rails`, `bin/bundle` |
| **APK** | Le fichier de l'app, qu'on installe sur le téléphone | L'image Docker qu'on déploie |
| **adb** | Ligne de commande pour parler au téléphone branché (installer, journaux, ports) | `kamal app exec`, `ssh` |
| **Android Studio** | L'éditeur officiel (basé sur IntelliJ), avec SDK, JDK et émulateur | RubyMine |
| **Maven Central / Google** | Dépôts de bibliothèques | rubygems.org |

## 3. Le dossier `android/`, fichier par fichier

```
android/
├── settings.gradle.kts          ← où chercher les bibliothèques, quels modules existent
├── build.gradle.kts             ← version du plugin Android (AGP)
├── gradle.properties            ← réglages de Gradle (mémoire, AndroidX)
├── gradlew, gradlew.bat         ← le wrapper : toujours lancer ./gradlew, jamais gradle
├── gradle/wrapper/              ← version de Gradle figée (9.9.2) + petit lanceur .jar
├── local.properties             ← NON versionné : chemin du SDK, URL de dev éventuelle
├── .gitignore
└── app/                         ← le seul module : l'application
    ├── build.gradle.kts         ← « Gemfile + config » de l'app
    └── src/
        ├── main/                ← le code et les ressources de toutes les versions
        │   ├── AndroidManifest.xml
        │   ├── kotlin/app/easyhome/android/
        │   │   ├── EasyHomeApplication.kt
        │   │   └── MainActivity.kt
        │   ├── assets/json/path-configuration.json
        │   └── res/             ← ressources : écrans XML, textes, couleurs, thème, icône
        └── debug/               ← ajouts valables seulement en debug
            ├── AndroidManifest.xml
            └── res/xml/network_security_config.xml
```

### Les fichiers de build (Gradle)

**`settings.gradle.kts`** : la liste des dépôts de bibliothèques (Google, Maven Central) et des modules du projet. Il
n'y a qu'un module, `:app`. C'est l'équivalent des lignes `source "https://rubygems.org"` d'un Gemfile.

**`build.gradle.kts` (racine)** : une seule ligne utile, la version du plugin Android (AGP 9.4). Depuis AGP 9, Kotlin
est intégré au plugin, donc pas de plugin Kotlin à déclarer.

**`app/build.gradle.kts`** : le fichier le plus important du build.

- `namespace` / `applicationId = "app.easyhome.android"` : l'identifiant unique de l'app sur le téléphone (et sur le
  Play Store un jour). Il ne change plus une fois publié.
- `compileSdk = 37` / `targetSdk = 37` : on compile avec les API d'Android 17 et on déclare en suivre les règles.
- `minSdk = 28` : l'app s'installe à partir d'Android 9.
- `versionCode` / `versionName` : numéro interne (entier qui doit augmenter à chaque publication) et numéro affiché.
- `buildTypes` : **debug** et **release**, l'équivalent des environnements Rails `development` et `production`.
- `buildConfigField("String", "BASE_URL", …)` : crée une constante `BuildConfig.BASE_URL`, utilisable dans le Kotlin.
  C'est l'équivalent d'une variable d'environnement figée dans l'app au moment du build.
  - en debug : `http://localhost:3000` (voir « adb reverse » plus bas), modifiable dans `local.properties` ;
  - en release : `https://easyhome.invalid`, une adresse volontairement invalide en attendant le déploiement.
- `dependencies` : les « gems ».
  - `dev.hotwire:core` : la WebView pilotée par Turbo, le chargement des règles et le sélecteur de fichiers ;
  - `dev.hotwire:navigation-fragments` : les écrans, la pile de navigation et les modals ;
  - `com.google.android.material` : les composants visuels Material (barre du haut, thème).

**`gradlew` et `gradle/wrapper/`** : ils garantissent que tout le monde (toi, la CI, Android Studio) utilise la même
version de Gradle, téléchargée automatiquement au premier lancement. Le `.jar` est un petit lanceur, pas du code à
lire.

**`local.properties`** : fichier personnel, jamais versionné. Il contient le chemin du SDK sur ton Mac, et au besoin
une autre URL de serveur. C'est l'équivalent d'un `.env` local.

### Le manifeste : `src/main/AndroidManifest.xml`

C'est la carte d'identité de l'app, lue par Android avant de lancer quoi que ce soit.

- `<uses-permission android:name="android.permission.INTERNET" />` : l'app a le droit d'aller sur le réseau. Chaque
  capacité sensible (internet, notifications, appareil photo…) se déclare ici.
- `<application android:name=".EasyHomeApplication" …>` : la classe lancée en premier, au démarrage de l'app.
  - `allowBackup="false"` : Android ne sauvegarde pas les données de l'app (dont le cookie de session) dans le cloud.
  - `theme`, `icon`, `label` : apparence et nom affiché sous l'icône.
- `<activity android:name=".MainActivity" …>` : le seul écran « système » de l'app. L'`intent-filter`
  `MAIN` / `LAUNCHER` dit « c'est celui qu'on ouvre quand on touche l'icône ».
  - `exported="true"` : obligatoire pour que le lanceur du téléphone puisse l'ouvrir.
  - `launchMode="singleInstance"` : une seule instance de l'app, même si on la rouvre depuis une notification.
  - `windowSoftInputMode="adjustResize"` : la page se redimensionne quand le clavier s'ouvre.

### La variante debug : `src/debug/`

Gradle fusionne ces fichiers avec ceux de `main`, **seulement en debug**, comme `config/environments/development.rb`.

- `network_security_config.xml` : Android interdit le http non chiffré par défaut. On l'autorise **uniquement en debug
  et uniquement vers `localhost`**, pour joindre le serveur de dev. La version release reste en https obligatoire.

### Le code Kotlin : deux classes

**`EasyHomeApplication.kt`**, l'équivalent de `config/initializers/`. Il s'exécute une fois au lancement de l'app :

- `webViewDebuggingEnabled` : en debug, la WebView s'inspecte depuis Chrome sur le Mac (`chrome://inspect`).
- `applicationUserAgentPrefix = "EasyHome Android;"` : début du user agent envoyé à Rails. Hotwire y ajoute
  « Hotwire Native Android », ce qui permet à Rails de reconnaître l'app avec `hotwire_native_app?` (fourni par
  `turbo-rails`), par exemple pour masquer l'en-tête web.
- `logger.logLevel` : journaux détaillés en debug, aucun en release.
- `Hotwire.loadPathConfiguration(…)` : charge les règles de navigation (section 4.3).

**`MainActivity.kt`**, le conteneur de tous les écrans :

- `HotwireActivity` : la classe de Hotwire dont on hérite. Elle sait gérer la pile d'écrans, le bouton retour, etc.
- `setContentView(R.layout.activity_main)` : affiche le layout XML (un simple conteneur, voir ci-dessous).
- `enableEdgeToEdge()` et `applyDefaultImeWindowInsets()` : l'app dessine jusqu'aux bords de l'écran, sans passer sous
  la barre d'état ni sous le clavier.
- `navigatorConfigurations()` : déclare **un navigateur** nommé `main`, qui démarre sur `BuildConfig.BASE_URL`.

Note sur `R.layout.activity_main` : `R` est une classe générée par le build qui donne un identifiant à chaque
ressource. C'est un peu l'équivalent des helpers de routes générés par Rails (`plants_path`).

### Les ressources : `src/main/res/`

L'équivalent combiné de `app/views`, `config/locales` et `app/assets`.

- `layout/activity_main.xml` : un seul élément, `NavigatorHost`, la zone où Hotwire affiche les écrans.
- `values/strings.xml` : les textes de la coque, ici seulement le nom « Easy Home ». C'est le `fr.yml` d'Android.
- `values/colors.xml` et `values/themes.xml` : couleurs (le vert emerald-700 de l'app web) et thème Material.
- `drawable/ic_launcher_foreground.xml` et `mipmap-anydpi/ic_launcher.xml` : l'icône (une feuille blanche sur fond
  vert), dessinée en vectoriel pour s'adapter à toutes les formes d'icônes des fabricants.

### La copie des règles : `src/main/assets/json/path-configuration.json`

Les `assets` sont des fichiers bruts embarqués dans l'APK. Celui-ci est la copie de secours des règles de navigation,
utilisée tant que le serveur n'a pas répondu (section 4.3).

## 4. Hotwire Native : les concepts

### 4.1 Les briques Android utilisées

- **Activity** : une fenêtre de l'app. On n'en a qu'une, `MainActivity`.
- **Fragment** : un écran à l'intérieur d'une activity. Chaque page Rails visitée devient un fragment
  (`HotwireWebFragment`), empilé sur le précédent, comme les cartes d'une pile.
- **WebView** : le navigateur intégré. Hotwire **réutilise la même WebView** d'un écran à l'autre : elle est détachée
  de l'ancien fragment, rattachée au nouveau, et Turbo y fait la visite. C'est ce qui rend la navigation rapide (pas de
  rechargement complet de JavaScript et de CSS).

### 4.2 Une visite, de bout en bout

Ce que montrent les journaux (`adb logcat`) quand tu touches « + Ajouter une plante » :

1. Turbo, dans la WebView, intercepte le clic comme il le fait dans Chrome.
2. Au lieu de visiter lui-même, Turbo **propose** la visite à la coque native (`visitProposedToLocation`).
3. La coque cherche les **règles** qui correspondent à l'URL `/plants/new` (section 4.3) : contexte `modal`.
4. Le **routeur** décide qui traite l'URL (`routeDecision: NAVIGATE`) :
   - une URL du même site reste dans l'app (`AppNavigationRouteDecisionHandler`) ;
   - un lien vers un autre site s'ouvre dans un onglet Chrome intégré (`BrowserTabRouteDecisionHandler`) ;
   - `mailto:`, `tel:`… partent vers l'app système correspondante (`SystemNavigationRouteDecisionHandler`).
5. Le **navigateur** (`Navigator`) crée un nouveau fragment, en modal, et l'anime par-dessus l'écran courant.
6. La WebView est déplacée dans ce fragment et Turbo charge la page.

À la soumission du formulaire, Rails répond par une redirection vers la fiche de la plante. Cette URL n'est pas une
modal : la coque **ferme la modal** et affiche la fiche dans la pile principale.

Plus précisément (code de `NavigatorRule` et `Navigator`, version 1.4.1), la coque ferme la modal puis rejoue la
redirection sur l'écran d'en dessous :

- si la redirection mène **à l'écran d'en dessous** (modifier une plante depuis sa fiche, ajouter une tâche), cet
  écran est **remplacé** par une version fraîche : la modal se ferme et la fiche est à jour, sans écran en plus ;
- sinon (ajouter une plante depuis l'accueil), la nouvelle page est **empilée** dans la pile principale ;
- si elle mène à une URL `replace_root` (l'accueil), la pile entière est remplacée.

Une simple redirection Rails suffit donc. Les helpers `recede_or_redirect_to` / `refresh_or_redirect_to` de
turbo-rails ne sont pas nécessaires ici, et `recede` ferait même revenir d'un écran de trop : la modal fermée, la coque
rejoue « revenir » sur l'écran d'en dessous.

### 4.3 La path configuration (règles de navigation)

Un fichier JSON qui dit, pour chaque motif d'URL, comment afficher l'écran. Les règles actuelles
(`config/hotwire/android_v1.json`) sont :

| Motifs | Effet |
|---|---|
| `.*` (tout) | Écran normal empilé ; tirer vers le bas pour rafraîchir |
| `/new($\|\?)`, `/edit($\|\?)` | Formulaire en **modal** plein écran, sans tirer pour rafraîchir |
| `/households($\|\?)` | Choix du foyer en **modal** ; le choix redirige vers l'accueil, qui remplace la pile |
| `^/($\|\?)`, `/session/new…`, `/passwords/new…` | Écran normal qui **remplace toute la pile** |

Ce qu'il faut savoir :

- **La dernière règle qui correspond l'emporte.** On écrit donc du général au particulier, comme des `rescue_from`
  qu'on surcharge.
- Les motifs sont des expressions régulières cherchées dans **le chemin et la query string** (`/plants/new?x=1`).
  D'où `($|\?)` plutôt que `$` pour dire « le chemin s'arrête là ».
- Les propriétés principales :
  - `context` vaut `default` (pile principale) ou `modal` (par-dessus, se ferme avec la croix ou retour) ;
  - `presentation` vaut par exemple `push` (empiler, par défaut), `replace` (remplacer l'écran courant),
    `replace_root` (vider la pile et repartir de cet écran), `pop`, `refresh`, `clear_all` ou `none` ;
  - `uri` indique quel type d'écran natif utiliser : `hotwire://fragment/web` pour un écran web, ou plus tard un
    écran 100 % natif ;
  - `pull_to_refresh_enabled` autorise ou non le geste « tirer pour rafraîchir ».
- Pourquoi la connexion remplace la pile : elle finit par `/new` et s'ouvrait donc en modal. Après la connexion, la
  modal se refermait sur une page qui n'existait plus, et l'app restait figée. Avec `replace_root`, la connexion et
  l'accueil repartent d'une pile vide, et le bouton retour ne ramène jamais à l'écran de connexion.
- **D'où viennent les règles** : l'app charge d'abord la copie embarquée, puis la dernière version mise en cache, puis
  télécharge celle du serveur en arrière-plan (`GET /configurations/android_v1`) et la met en cache. On change donc la
  navigation **sans republier l'app**. Le `v1` dans l'URL ne change jamais de sens : un changement incompatible
  passera par un `v2`, pour ne pas casser les apps déjà installées.

### 4.4 La confiance des origines

Depuis la version 1.4, Hotwire ne donne accès aux capacités natives (pont JavaScript ↔ Kotlin, choix de fichiers,
appareil photo) qu'aux sites de confiance. Par défaut, c'est l'origine de départ, `http://localhost:3000` en debug. Un
site tiers ouvert dans l'app n'a donc jamais accès à l'appareil photo.

### 4.5 La photo : pourquoi elle marche déjà

Dans Chrome sur Android, un `<input type="file" accept="image/*">` propose la galerie. Dans une WebView brute, rien ne
se passe : c'est à l'app de gérer le choix de fichiers. Hotwire Native le fait pour nous
(`FileChooserDelegate` et `CameraCaptureDelegate`) : il ouvre le sélecteur du téléphone, appareil photo compris, et
renvoie le fichier à la page. Le formulaire Rails reçoit la photo comme depuis un navigateur.

### 4.6 La session et les cookies

La WebView garde ses cookies comme Chrome. Le cookie de session Rails (authentification du générateur Rails 8)
fonctionne donc sans rien changer, et reste valable d'un lancement à l'autre. Un vidage des données de l'app
(`adb shell pm clear app.easyhome.android`) déconnecte.

### 4.7 Les bridge components (pas encore utilisés)

Le pont permet à une page web de demander quelque chose au natif, par exemple « affiche un bouton Enregistrer dans la
barre du haut ». Il a deux moitiés :

- un **contrôleur Stimulus** côté Rails (`app/javascript/controllers/bridge/`) ;
- un **composant Kotlin** enregistré dans `EasyHomeApplication`.

Ils s'échangent des messages JSON. Ce sera utile pour rendre la navigation plus naturelle (boutons natifs, menus).

## 5. Côté Rails

- `app/controllers/configurations_controller.rb` : sert les règles, sans authentification (l'app les télécharge
  avant la connexion). Le contenu est fixe et ne contient rien de sensible.
- `config/hotwire/android_v1.json` : la source des règles.
- `spec/requests/configurations_spec.rb` : vérifie le contenu des règles et que la copie embarquée dans l'app est
  identique à celle du serveur.
- Rien d'autre n'a changé : toutes les pages sont les mêmes que dans le navigateur.

## 6. Le cycle de développement

```
Mac                                                  Téléphone (branché en USB)
───                                                  ──────────────────────────
bin/dev            → Rails écoute sur localhost:3000
adb reverse tcp:3000 tcp:3000  ─────────────────────► localhost:3000 du téléphone = celui du Mac
cd android && ./gradlew installDebug  ──────────────► installe l'APK de debug
adb logcat ...     ◄───────────────────────────────── journaux de l'app
Chrome : chrome://inspect  ◄────────────────────────── inspecteur de la WebView (console, réseau, DOM)
```

- **`adb reverse`** fait passer le port 3000 du téléphone par le câble jusqu'au Mac. L'app parle donc à
  `localhost:3000` : aucune adresse IP dans le code, rien d'ouvert sur le Wi-Fi. À refaire à chaque branchement.
- **Modifier une page** : comme d'habitude côté Rails, puis tirer pour rafraîchir dans l'app. Pas de rebuild Android.
- **Modifier les règles** : éditer `config/hotwire/android_v1.json` **et** la copie dans `android/` (la spec le
  rappelle). L'app prend la nouvelle version au plus tard au lancement suivant.
- **Modifier la coque** (Kotlin, manifeste, ressources) : `./gradlew installDebug`, puis relancer l'app.
- **Repartir de zéro** : `adb shell pm clear app.easyhome.android` (déconnecte et vide le cache).

Ce qui se passe au lancement, d'après les journaux :

1. Android crée `EasyHomeApplication` : configuration et chargement des règles.
2. Android ouvre `MainActivity` : le navigateur `main` visite `BASE_URL` (`/`).
3. Rails redirige vers `/session/new` si tu n'es pas connecté ; la règle `replace_root` s'applique.
4. La page est chargée à froid (*cold boot*) : HTML, CSS et JavaScript complets, une seule fois.
5. Turbo signale qu'il est prêt (`turboIsReady`) ; les visites suivantes passent par Turbo, sans rechargement complet.

## 7. Debug et release

| | Debug | Release |
|---|---|---|
| Serveur | `http://localhost:3000` via `adb reverse` | URL https de production (étape 4 de la roadmap) |
| http en clair | Autorisé vers `localhost` seulement | Interdit |
| Inspecteur Chrome, journaux | Oui | Non |
| Signature | Clé de debug générée automatiquement | Clé personnelle, à garder hors du dépôt (à créer) |
| Installation | `./gradlew installDebug` | APK signé installé à la main, ou piste de test du Play Store |

Une app Android doit être **signée** pour s'installer. En debug, Android Studio utilise une clé jetable. Pour une
version durable, il faudra une clé à nous : la perdre empêche de mettre à jour l'app installée.

## 8. La CI

Le job « Android » de `.github/workflows/ci.yml` installe Java 21 et lance `./gradlew assembleDebug` dans
`android/`. Il prouve que la coque compile à chaque PR. Il ne teste pas encore le comportement : la coque n'a pas de
logique à tester, et les parcours restent couverts par les system specs Rails. Dependabot propose les mises à jour des
dépendances Gradle chaque semaine.

## 9. Glossaire

| Terme | Sens |
|---|---|
| APK | Le fichier installable de l'app |
| Activity | Une fenêtre Android ; ici `MainActivity`, la seule |
| adb | Outil en ligne de commande pour piloter un téléphone branché |
| AGP | Android Gradle Plugin, le plugin qui construit les apps Android |
| Bridge component | Paire Stimulus + Kotlin pour qu'une page demande un élément natif |
| BuildConfig | Constantes générées au build (`BASE_URL`, `DEBUG`) |
| Cold boot | Premier chargement complet d'une page dans la WebView |
| Context (`default`, `modal`) | Pile principale ou écran par-dessus |
| Fragment | Un écran dans une activity ; une page visitée = un fragment |
| Manifeste | Carte d'identité de l'app : permissions, écrans, classe de démarrage |
| Navigator / NavigatorHost | La pile d'écrans et la zone où elle s'affiche |
| Origin trust | Liste des sites qui ont accès aux capacités natives |
| Path configuration | Les règles de navigation par motif d'URL |
| Presentation | Comment un écran entre dans la pile : `push`, `replace`, `replace_root`… |
| `R` | Classe générée qui référence les ressources (`R.layout.activity_main`) |
| SDK (`minSdk`, `targetSdk`, `compileSdk`) | Versions d'Android : minimum supporté, règles suivies, API compilées |
| User agent | Texte d'identification envoyé à Rails ; contient « Hotwire Native » dans l'app |
| WebView | Navigateur intégré dans l'app |

## 10. Pistes pour la suite

Les questions qui se poseront, dans l'ordre probable :

- **Navigation plus naturelle** :
  - donner à chaque page un `<title>` précis (la barre native l'affiche) ;
  - masquer l'en-tête web et les liens « ← » web dans l'app, grâce à `hotwire_native_app?` ;
  - placer la déconnexion dans un menu natif (bridge component).
- **Notifications push** : projet Firebase, modèle `Device` et jeton d'API, réception dans la coque, action « Fait »
  depuis la notification.
- **Déploiement** : URL https de production dans la release, clé de signature, installation sur le téléphone.
