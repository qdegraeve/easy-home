# Revue UX et proposition de refonte

> Revue menée le 20 novembre 2026 sur la branche `main` (commit `ac81bca`), dans un viewport mobile 390 × 844, avec un
> compte et un foyer de démonstration fictifs (8 plantes, 3 emplacements, 2 tâches manuelles, une analyse terminée, une
> analyse en échec). Données supprimées après la revue. Maquettes de la refonte : `docs/maquettes/v2/index.html`.
> Décisions du propriétaire du 21 novembre 2026 intégrées (dernière section).

## Résumé exécutif

1. L'app fonctionne et le code est propre ; le problème est la **forme** : un accueil qui est en fait la liste des
   plantes, une fiche plante de 2,7 écrans avec 26 boutons, et une navigation qui n'existe que par des liens « ← ».
2. Le modèle « une tâche d'arrosage par plante » est juste pour les données, mais pas pour l'écran : il faut
   **regrouper à l'affichage** (« Arroser · 4 », validé d'un geste) sans changer le schéma, et laisser **la pluie**
   noter les arrosages des plantes dehors.
3. L'impression « IA » vient d'un faisceau précis : emojis dans chaque titre, cartes blanches arrondies et ombrées
   partout, deux couleurs primaires concurrentes, textes d'aide longs, maquettes en dégradés. On propose une identité
   « carnet de maison » : fond papier, encre, une seule couleur d'action, icônes au trait, couleurs par domaine.
4. Dans l'app Android, la coque n'a ni titres (« Easy Home » partout), ni onglets, et l'en-tête web s'ajoute à la barre
   native. Cible : **3 onglets natifs** (Aujourd'hui, Maison, Journal), titres par page, actions en barre native par
   bridge, en-tête web masqué dans l'app.
5. Ordre conseillé : coque et navigation d'abord (gain immédiat ressenti), puis accueil « Aujourd'hui » groupé, puis
   identité visuelle, puis fiche plante allégée. Dix PR courtes, chacune livrable seule.

## Principes directeurs

- **Un seul endroit pour ce qui est à faire aujourd'hui.** L'onglet « Aujourd'hui » est la raison d'ouvrir l'app ; tout
  le reste est de l'inventaire ou de l'historique.
- **Une ligne par geste, pas par objet.** On affiche ce que l'utilisateur va faire (« arroser »), pas la
  liste des objets concernés.
- **Dix secondes.** Ouvrir, valider, fermer. Tout ce qui n'aide pas à ça descend d'un niveau.
- **Le natif pour se déplacer, le web pour le contenu.** Onglets, titre, retour et menus dans la coque ; écrans métier
  en Rails.
- **Calme par défaut.** Le rouge est réservé à ce qui a vraiment des conséquences (poubelle ratée), pas à une plante
  arrosée avec un jour de décalage.
- **Un domaine = le même gabarit.** Plantes, poubelles, piscine, animaux, équipements partagent liste, fiche et ligne
  de tâche ; seule la section « spécifique » change.
- **Proposer, ne pas imposer.** L'IA reste une proposition, rangée dans la fiche, jamais en tête d'écran.

## Personas et contextes d'usage

- **Le responsable du foyer, le matin** · 7 h 30, café, notification du résumé · Voir ce qui est dû, cocher ce qui est
  fait · 10 s.
- **Le même, au jardin** · Arrosoir à la main, une main libre · Valider tout l'arrosage d'un geste · 5 s.
- **Le même, le soir** · Veille de collecte · « Sortir la poubelle jaune », valider en sortant · 5 s, souvent depuis la
  notification.
- **Un membre du foyer** · De temps en temps · Voir si c'est déjà fait, éviter de le faire deux fois · 5 s.
- **Un invité (voisin, pet-sitter)** · Pendant les vacances · Uniquement ses tâches ouvertes, rien d'autre · 10 s, sans
  formation.
- **L'amateur de plantes** · Le week-end, au calme · Photo, analyse, discussion, réglages fins · 2 à 5 min.

Conséquence : l'écran le plus vu doit être ultra court ; l'écran le plus riche (fiche, analyse) peut être long, mais
découpé.

## Remarque 1 : « Une tâche d'arrosage par plante alourdit l'expérience »

### Diagnostic

- `app/views/home/show.html.erb` : « À faire aujourd'hui » affiche **une ligne par échéance**. Avec 8 plantes de démo,
  5 lignes « Arrosage » + 1 « Engrais » dès le premier jour ; avec la dizaine de plantes réelles et des intervalles de
  2 à 4 jours, c'est 4 à 8 lignes « Arrosée » par jour, et autant de requêtes, de rechargements et de messages flash.
- Chaque validation recharge la page, insère un flash en haut qui **décale toute la liste** : le bouton suivant n'est
  plus sous le doigt (`app/views/layouts/_flash.html.erb`).
- Le libellé « en retard de 1 j » en rouge gras (`DueLabelComponent`) culpabilise pour une tâche souple : une plante
  arrosée un jour plus tard ne meurt pas.
- Le résumé du matin (ADR 0012) liste « arroser Basilic, arroser Citronnier, arroser Menthe… » : même noyade dans la
  notification.
- Quand poubelles, piscine, animaux et équipements arriveront, la liste plate deviendra illisible.

### Proposition

1. **Regrouper à l'affichage** les échéances de même nature : tout l'arrosage du jour sur une ligne, « Arroser · 4 ».
   Une ligne, un bouton « Fait ». Un appui sur la ligne déplie la liste (cases cochées par défaut, on décoche la plante
   qu'on a sautée). Détail dans « Modèle de tâches easy ».
2. **Deux niveaux d'importance** : « à ne pas rater » (poubelle, vermifuge) et « souple » (arrosage, entretien). Les
   souples ont une **tolérance** proportionnelle à leur fréquence : elles ne passent en retard qu'au-delà. La pluie
   note elle-même les arrosages dehors.
3. **Valider sans recharger** : réponse Turbo Stream qui retire la ligne, toast discret en bas avec « Annuler »
   pendant 5 s (le service `Tasks::CancelCompletion` existe déjà).
4. **Résumé du matin groupé** : « 3 choses aujourd'hui : arroser 4 plantes, sortir la poubelle jaune, engrais du
   citronnier ».

## Remarque 2 : « L'affichage est un peu fouillis »

### Diagnostic

- **L'accueil mélange trois rôles** (`home/show.html.erb`) : tâches du jour, inventaire complet groupé par emplacement,
  plantes archivées, plus le lien « Ma maison » et le bouton d'ajout tout en bas (sous 8 plantes, il faut défiler pour
  ajouter). Le titre « Mes plantes » est faux dès qu'il y a une tâche non liée aux plantes.
- **La fiche plante** (`plants/show.html.erb`) empile 6 sections au même niveau visuel : arrosage, autres tâches,
  analyse (avec la discussion complète et son formulaire), suivi photo (avec un formulaire d'envoi), journal, puis
  Modifier / Archiver / Supprimer. Mesuré : **2 257 px de haut (2,7 écrans), 26 éléments interactifs**, dont 18 de
  moins de 44 px de haut.
- **Tout est carte** : chaque section est une carte blanche arrondie ombrée sur fond gris, y compris les états vides et
  les boutons secondaires. Rien ne hiérarchise ; l'œil n'a pas de point d'entrée.
- **Boutons de même poids** : « Modifier », « Supprimer », « Annuler », « Fait », « Appliquer », « Ajouter aux tâches »
  n'ont pas de hiérarchie cohérente ; « Supprimer » une tâche est à 8 px de « Modifier » en `text-xs`.
- **Formulaires bruts** : champ fichier natif du navigateur (« Choose file / No file chosen », en anglais) sur la fiche,
  l'ajout et la discussion.
- **Répétitions** : « ← Mes plantes » en haut de chaque page alors que la barre native a déjà un retour ; « 💧 » trois
  fois sur la même carte.
- **Libellés** : « Toutes les plantes · 8 », « Analyses précédentes · 2 » (le point médian comme séparateur partout),
  « Fait » vs « Arrosée » vs « ✓ Sur la fiche » vs « ✓ En place » vs « ✓ Dans les tâches » pour le même concept
  « c'est fait ».

### Proposition

- Accueil = **Aujourd'hui** uniquement : en retard / aujourd'hui / bientôt (3 jours), groupés. L'inventaire part dans
  l'onglet **Maison**.
- Fiche = **en-tête + prochaine action + 3 onglets internes** (Soins, Photos, Historique). L'analyse IA devient une
  carte « État » compacte en haut des Photos, la discussion part sur sa propre page.
- **Listes à filets** plutôt que cartes : une seule surface blanche par groupe, séparateurs fins, pas d'ombre. Les
  cartes sont réservées aux éléments actionnables (la ligne de tâche du jour).
- Actions destructives et rares (Modifier, Archiver, Supprimer) dans le **menu ⋮ natif** de la barre.
- Un vocabulaire unique pour « c'est fait » : bouton **« Fait »** partout (« Arrosé » seulement comme libellé de
  journal), coche verte pour l'état fait.

## Remarque 3 : « Le thème fait un peu trop IA »

### Ce qui donne cette impression, précisément

- **Emoji en tête de chaque titre de section** (`fr.yml` : `💧 Arrosage`, `📒 Journal`, `🌿 Autres tâches`, `📷 Suivi
  photo`, `🔍 Analyse`, `📍 Situation`, `🪴 Emplacements`, `🏡 Ma maison`, `🔔`) : c'est la signature des textes et
  interfaces produits par un LLM ; rendus différemment selon le téléphone, ils ne s'alignent pas sur la ligne de texte.
- **Emojis comme valeurs de données** (`☀️ Plein soleil`, `⛅ Mi-ombre`, `☁️ Ombre`, `✅ En forme`, `👀 À surveiller`, `⚠️
  À traiter`, `⏳ Analyse en cours…`) : mélange de styles d'icônes, aucune cohérence de taille ni de couleur.
- **Cartes `rounded-2xl bg-white shadow-sm` sur `bg-stone-50`, partout** (Toutes les vues) : le gabarit par défaut des
  générateurs d'UI Tailwind ; aucune personnalité.
- **Deux couleurs primaires** (`emerald-700` (liens, boutons pleins) et `sky-600` (Arrosée / Fait)) : aucun sens porté
  par la couleur ; on hésite sur ce qui est l'action principale.
- **Sur-titre en capitales espacées** (`uppercase tracking-wide text-emerald-700` (accueil, connexion)) : tic de landing
  page SaaS.
- **Dégradés pastel avec emoji au centre** (`docs/maquettes/*.html` (`from-rose-300 to-emerald-500`…)) : le cliché
  visuel des maquettes générées.
- **Bulles de chat vert pâle / gris** (`analysis_questions/_thread.html.erb`) : copie de l'interface d'un assistant
  conversationnel.
- **Textes d'aide longs et rassurants** (« La page se mettra à jour toute seule. », « une photo de temps en temps permet
  de voir son évolution. ») : le ton explicatif et poli des réponses d'assistant.
- **« + » en texte dans les boutons** (« + Ajouter une plante », « + Nouveau foyer ») : pas d'icône réelle, effet
  brouillon.

### Identité proposée : « carnet de maison »

Idée : un objet du quotidien, sobre, qui ressemble à un carnet d'entretien bien tenu plutôt qu'à une startup. Papier,
encre, un vert sombre pour agir, et une couleur discrète par domaine pour se repérer.

**Palette** (contrastes vérifiés sur le fond papier ; AA = 4,5:1 minimum pour le texte courant)

| Rôle | Nom | Valeur | Usage |
|---|---|---|---|
| Fond | Papier | `#F6F4EF` | Fond d'écran |
| Surface | Blanc cassé | `#FFFFFF` | Groupes de listes, feuilles modales |
| Filet | Trait | `#E4E0D6` | Séparateurs, bordures de champ |
| Texte | Encre | `#1D2521` | Titres et texte (14,3:1) |
| Texte secondaire | Graphite | `#5F665F` | Méta-informations (5,4:1) |
| Action | Vert sapin | `#1F5C46` | Bouton principal, onglet actif, liens (7,1:1) |
| Action, fond léger | Vert sapin 10 % | `#E3EDE7` | Bouton secondaire, ligne faite |
| Alerte | Brique | `#A8402A` | Uniquement « à ne pas rater » en retard (5,6:1) |
| Attention | Ocre | `#8A6200` | À surveiller (5,0:1) |
| Domaine plantes | Feuille | `#3F7D4E` | Pastille, icône |
| Domaine poubelles | Moutarde | `#B98A00` | Pastille (rappel du bac jaune) |
| Domaine piscine | Lagon | `#1F7A99` | Pastille |
| Domaine animaux | Terre cuite | `#B0603A` | Pastille |
| Domaine équipements | Ardoise | `#55657A` | Pastille |

Règles : une seule couleur d'action (vert sapin) ; les couleurs de domaine ne servent qu'aux **pastilles et icônes**,
jamais aux boutons ni aux grands aplats ; pas de dégradé ; ombres réservées aux feuilles modales et au toast. Un thème
sombre se déduit des mêmes jetons (à faire plus tard ; la coque est en thème clair fixe). Mis en place en PR 3
(ADR 0013).

**Typographie** : la police système (Roboto sur Android, San Francisco sur iOS). Dans une webview, c'est ce qui donne
l'impression « app native » et ça ne coûte aucun téléchargement. Échelle courte : titre d'écran 22/28 semi-gras,
titre de groupe 13/18 semi-gras graphite (casse normale, pas de capitales espacées), corps 16/22, méta 14/20, chiffres
tabulaires pour les dates et compteurs. Le nom « Easy Home » n'apparaît qu'à la connexion.

**Icônes** : un jeu d'icônes au trait unique, **Lucide** (licence ISC, maintenu, plus de 1 500 icônes, SVG inline sans
dépendance JS), en 20 px, trait 1,75, couleur du texte ou du domaine. Pourquoi plutôt que les emojis : rendu identique
sur tous les téléphones, alignement sur la ligne, couleur contrôlée, accessibles (`aria-hidden` + libellé texte), et un
style unique. Intégration proposée : copier les SVG utilisés dans `app/assets/images/icons/` et un `IconComponent`
(pas de gem ni de paquet npm nécessaire). Correspondance : arrosage `droplet`, poubelle `trash-2`, piscine `waves`,
animal `paw-print`, équipement `wrench`, photo `camera`, état `activity`, journal `history`, soleil `sun`, mi-ombre
`cloud-sun`, ombre `cloud`, abri `shield`, maison `house`, réglages `sliders-horizontal`. Les emojis peuvent rester
dans le **contenu saisi** par l'utilisateur, jamais dans l'interface.

**Ton** : phrases courtes, à l'infinitif pour les actions (« Arroser », « Sortir la poubelle »), sans « ⏳ » ni
« toute seule ». Un état vide = une phrase + une action. Les explications longues vont dans un lien « En savoir plus ».

**Composants de base** (voir `docs/maquettes/v2/composants.html`)

- **Ligne de tâche** : pastille de domaine 36 px avec icône, titre (verbe + objet), méta (lieu · nombre), bouton rond
  « Fait » 44 × 44 à droite. Appui long ou appui sur le texte : détail.
- **Groupe de liste** : titre de groupe 13 px graphite au-dessus, surface blanche, filets, rayon 14 px, sans ombre.
- **Bouton** : principal plein vert sapin, hauteur 48, rayon 12 ; secondaire fond vert 10 % ; tertiaire texte ;
  destructif texte brique, toujours derrière une confirmation.
- **Badge d'échéance** : texte seul, pas de pastille de couleur. « aujourd'hui » en encre et gras, « demain »,
  « dans 4 j » en graphite, « prévu hier », « prévu il y a 3 j » en graphite pour une tâche souple (fait en PR 4,
  `DueLabelComponent`) ; « En retard · 2 j » en brique pour une tâche à ne pas rater uniquement (PR 10).
- **État vide** : icône au trait 32 px graphite, une phrase, un bouton secondaire. Pas d'emoji géant centré.
- **Toast** : en bas, au-dessus de la barre d'onglets, fond encre, texte blanc, action « Annuler », 5 s, ne décale
  jamais le contenu (remplace les flashs en haut de page).

## Remarque 4 : « La navbar / le menu côté app est à revoir »

### Diagnostic

- `app/views/layouts/application.html.erb` : l'en-tête web (« Easy Home », 🔔, « Se déconnecter ») s'affiche **aussi
  dans l'app**, sous la barre native. Deux barres, deux titres, et « Se déconnecter » à un pouce de la cloche, sans
  confirmation.
- Aucune vue ne remplit `content_for(:title)` : la barre native affiche **« Easy Home » sur tous les écrans** (le titre
  de l'onglet du navigateur pendant la revue l'est aussi).
- `MainActivity` : un seul navigateur, pas d'onglets. On ne passe d'une zone à l'autre que par des liens dans les pages
  (« 🏡 Ma maison », le nom du foyer en sur-titre pour changer de foyer, 🔔 pour les réglages).
- Liens « ← Mes plantes », « ← Retour », « ← Accueil » en haut de chaque page **en plus** du retour Android et de la
  flèche native : trois façons de revenir, dont une (le lien web) qui **empile** un nouvel écran au lieu de revenir.
- `config/hotwire/android_v1.json` : `/` est en `replace_root`, donc chaque lien vers l'accueil vide la pile (transition
  brutale) ; les formulaires `/new` et `/edit` s'ouvrent en modal, mais après l'envoi la redirection pousse un nouvel
  écran au lieu de fermer la modal et de rafraîchir l'écran d'en dessous.
- `/households` (changer de foyer) n'a ni retour web ni lien vers « Ma maison » ; « Ma maison » n'est accessible que
  depuis l'accueil.
- Le menu de la fiche plante (Modifier, Archiver, Supprimer) est en bas de page, après 2,7 écrans de défilement.

### Proposition

Voir la section suivante pour l'architecture complète. En bref :

1. **Barre d'onglets native** (Hotwire Native Android sait gérer des onglets avec un navigateur par onglet) :
   Aujourd'hui, Maison, Journal. Les réglages sont dans un bouton de la barre d'Aujourd'hui.
2. **Titre natif par page** via `content_for(:title)` ; **en-tête web masqué** quand `hotwire_native_app?`.
3. **Liens « ← » web supprimés dans l'app** (gardés seulement dans le navigateur, ou remplacés par un fil d'Ariane sur
   grand écran).
4. **Actions dans la barre native** par bridge components : bouton « Ajouter » (+), menu ⋮ (Modifier, Archiver,
   Supprimer).
5. **Formulaires en modal qui se referment** après envoi, avec rafraîchissement de l'écran précédent
   (déjà le comportement de Hotwire Native après une redirection vers l'écran d'en dessous).

## Architecture de l'information et navigation cible

### Arborescence

```
Aujourd'hui (onglet 1)            ← ouverture de l'app, notification du matin
  ├─ En retard · Aujourd'hui · Bientôt (3 jours)
  ├─ Détail d'un groupe (« Arroser · 4 ») — feuille modale
  └─ [barre] sélecteur de foyer (titre) · Réglages (icône)

Maison (onglet 2)                 ← inventaire, par domaine
  ├─ Plantes ─ liste par emplacement ─ fiche plante ─ Soins | Photos | Historique
  │                                                    └─ analyse, discussion, photo (push)
  ├─ Poubelles ─ fiche « Poubelle jaune » (collecte, prochaines dates)
  ├─ Piscine ─ fiche (filtration, chlore, relevés)
  ├─ Animaux ─ fiche par animal
  ├─ Équipements ─ fiche par équipement
  └─ Lieux de la maison (adresse, emplacements)

Journal (onglet 3)                ← ce qui a été fait, par qui, quand ; filtres par domaine ; annuler

Réglages (depuis Aujourd'hui)     ← compte, notifications, foyers et membres, invités, déconnexion
```

### Pourquoi 3 onglets et pas 5

- 5 onglets par domaine (Plantes, Poubelles…) ne tiennent pas : le nombre de domaines grandit, et un foyer sans
  piscine aurait un onglet vide. Les domaines sont des **sections de Maison**, affichées seulement si le foyer en a.
- « Ajouter » n'est pas un onglet : c'est une action contextuelle (bouton + de la barre native), qui ouvre une feuille
  « Que voulez-vous ajouter ? » depuis Maison, ou directement le bon formulaire depuis une liste de domaine.
- Réglages et foyer sont rares : hors des onglets. Le **foyer actif** est le titre de l'onglet Aujourd'hui (appui :
  feuille de choix du foyer), comme un sélecteur de compte.
- Un **invité** n'a qu'un onglet utile : Aujourd'hui filtré sur ses tâches. Rails renvoie une configuration d'onglets
  réduite ou masque Maison et Journal (lot
  « invités », hors de cette refonte).

### Natif ou web

- **Barre d'onglets (Aujourd'hui, Maison, Journal)** · natif : Oui : un navigateur par onglet, état conservé · web : —.
- **Titre de la barre** · natif : Lu dans `<title>` · web : `content_for(:title)` sur chaque vue.
- **Bouton retour** · natif : Oui, flèche native et geste système · web : Liens « ← » masqués dans l'app.
- **Bouton d'action (+, Enregistrer)** · natif : Bridge component `button` · web : Déclaré par un élément
  `data-controller="bridge--button"`.
- **Menu ⋮ (Modifier, Archiver, Supprimer)** · natif : Bridge component `menu` (liste native) · web : Déclare les
  entrées et leurs URL.
- **Feuille de choix du foyer** · natif : Modal native par path configuration · web : Page `/households`.
- **Confirmation de suppression** · natif : Plus tard : bridge `alert` (boîte native) · web : Aujourd'hui : `<dialog>`
  existant, qui suffit.
- **Toast « Fait · Annuler »** · natif : — · web : Turbo Stream + Stimulus (identique web et app).
- **Contenu de tous les écrans** · natif : — · web : Oui.

### Règles de path configuration proposées

- `.*` → `default`, push : Écran normal, tirer pour rafraîchir.
- `/new($|\?)`, `/edit($|\?)` → `modal` : Formulaires en feuille, sans tirer pour rafraîchir.
- `/households($|\?)` → `modal` : Choix du foyer, se ferme après le choix.
- `/today/groups/` → `modal` : Détail d'un groupe de tâches.
- `/settings` → `default`, push : Pile propre aux réglages.
- `^/($|\?)`, `/maison($|\?)`, `/journal($|\?)` → `default`, `replace_root` dans **leur** onglet : Racines d'onglet ; un
  lien vers une racine bascule d'onglet au lieu d'empiler.
- `/session/new`, `/passwords/new` → `default`, `replace_root` : Inchangé (piège documenté).

Après un formulaire en modal : une redirection Rails ordinaire vers l'écran d'en dessous ferme la modal et recharge
cet écran (comportement de Hotwire Native Android, vérifié dans son code ; voir `docs/android-coque.md`, 4.2).

Transitions : push latéral pour descendre dans l'arborescence, feuille montante pour les formulaires, aucun
`replace_root` hors racines d'onglet et authentification. C'est ce qui corrigera l'impression de « mauvaises
transitions » (aujourd'hui, revenir à l'accueil par un lien web efface la pile en fondu).

## Modèle de tâches « easy » : éviter la noyade

### Constat chiffré

Avec 10 plantes arrosées tous les 2 à 4 jours, il y a en moyenne **3 à 4 arrosages par jour**, plus les tâches des
autres domaines. Quand poubelles (2 par semaine), piscine (2 à 3 par semaine), animaux (1 par semaine) et équipements
arriveront, une liste plate dépassera 8 lignes certains jours, chacune avec son bouton. C'est exactement la noyade que
le nom « easy » promet d'éviter.

### Mécanismes proposés (du moins coûteux au plus structurant)

1. **Regroupement à l'affichage** (sans changement de schéma, **décidé** : tout l'arrosage du jour sur une ligne).
   Les échéances ouvertes du jour sont regroupées par `template_key` : « Arroser · 4 », sous-titre « Terrasse 3 ·
   salon 1 ». Une ligne, un bouton « Fait » qui valide les quatre. Appui sur la ligne : feuille avec les plantes
   cochées, rangées par emplacement ; on décoche celles qu'on n'a pas faites. Une échéance seule s'affiche comme
   aujourd'hui. Les tâches manuelles ne se regroupent pas.
2. **Validation groupée** : un service `Tasks::CompleteMany` qui appelle `Tasks::Complete` pour chaque échéance dans
   une transaction, et renvoie la liste pour le toast « 3 arrosages notés · Annuler » (l'annulation appelle
   `Tasks::CancelCompletion` pour chacune).
3. **Importance** : chaque tâche est **souple** (arrosage, entretien, engrais) ou **à ne pas rater** (poubelle,
   médicament, vermifuge). Seules les « à ne pas rater » apparaissent en rouge, en tête, et déclenchent une relance.
   Valeur par défaut fixée par le modèle de tâche du catalogue ; modifiable par tâche.
4. **Tolérance proportionnelle** (**décidé**) : la marge d'une tâche souple dépend de sa fréquence, une plante
   arrosée chaque jour est plus vite en retard qu'une plante arrosée chaque semaine. Règle proposée :
   `marge = arrondi(intervalle × 0,25)`, bornée entre 0 et 3 jours (1 jour → 0, 3 jours → 1, 7 jours → 2,
   14 jours → 3). Pendant la marge, la tâche reste dans « Aujourd'hui » avec la mention « depuis hier », sans rouge ;
   elle n'est marquée `missed` qu'au bout de la marge. La météo s'y ajoute (section suivante).
5. **« Bientôt » replié** : les 3 jours suivants sont un simple compteur repliable (« Bientôt · 6 »), pour anticiper
   sans encombrer.
6. ~~**Rythme par emplacement**~~ : **écarté**. Chaque plante garde son propre rythme ; le regroupement à
   l'affichage et la pluie suffisent à alléger la liste.
7. **Décaler** : sur une ligne, « Demain » (glisser ou menu) plutôt que de laisser une tâche rouge. **Décidé** : le
   report laisse une trace discrète dans le journal (« Décalé à demain · Sam »), sans compter comme fait ni comme
   manqué. Raison : une tâche reportée trois fois de suite doit se voir, c'est le signe que sa fréquence est mauvaise ;
   et la trace explique pourquoi l'échéance a bougé quand un autre membre du foyer la cherche.
8. **Résumé du matin groupé** avec la même règle que l'écran, et rien pour les tâches souples encore dans leur marge
   si l'utilisateur le choisit (« Notifier seulement ce qui ne doit pas être raté »).

### Arrosage et météo (décidé, à concevoir en ADR)

La pluie arrose les plantes dehors : une tâche « arroser » le lendemain d'une grosse pluie est du bruit, et c'est
exactement ce qui fait décrocher d'une app de rappels.

- **Quand** : un job chaque soir (vers 22 h, heure du foyer), avant le résumé du matin.
- **Données** : le cumul de pluie du jour à la position de la maison (`households.latitude` / `longitude`), par l'API
  Open-Meteo déjà retenue en ADR 0009 (gratuite, sans clé), derrière un adaptateur `Weather` avec un faux en test.
- **Qui est concerné** : les échéances d'arrosage ouvertes ou dues le lendemain, pour les plantes d'un emplacement
  **non abrité** (`locations.sheltered = false`). Les plantes d'intérieur ou abritées ne sont jamais touchées.
- **Règle** : au-delà d'un seuil (proposé : 10 mm sur la journée), l'arrosage est noté fait par la pluie : l'échéance
  est complétée avec la source « pluie », la suivante repart de ce jour (récurrence glissante). Entre 3 et 10 mm,
  l'échéance est repoussée d'un jour sans être notée faite. Sous 3 mm, rien. Seuils à affiner à l'usage.
- **Affichage** : dans « Aujourd'hui », une ligne discrète « Pluie cette nuit, 14 mm : jardin devant arrosé » ; dans
  le journal, « Arrosées par la pluie · 2 · automatique », annulable comme une validation manuelle.
- **Impacts sur les données** : source de la réalisation (`manual` / `rain`) sur l'échéance complétée, cumul de pluie
  journalier stocké (une ligne par foyer et par jour) pour l'historique et pour éviter de rappeler l'API.
- **Plus tard** : tenir compte de la taille du pot ou du besoin en eau de l'espèce (une plante en pot sous un auvent
  partiel ne reçoit pas toute la pluie), et des prévisions (ne pas arroser s'il pleut demain).

### Changement d'emplacement et analyses (proposition, à valider avant la PR 6)

L'analyse d'une plante tient compte de son lieu (exposition, abri du vent). Si l'emplacement change (emplacement
modifié, plante déplacée, emplacement supprimé), ses observations et ses propositions (intervalle d'arrosage, actions)
peuvent ne plus être justes. Aujourd'hui, rien ne le signale : une analyse ne garde pas le lieu dans lequel elle a été
faite.

- **Garder le lieu de l'analyse** : à la création, l'analyse enregistre le contexte envoyé à l'IA (nom de
  l'emplacement, exposition, abri). L'historique peut alors dire « analysée en mi-ombre, abritée ».
- **Signaler, ne pas relancer tout seul** : quand le lieu actuel de la plante diffère de celui de sa dernière analyse,
  la fiche affiche une carte discrète : « Exposition changée depuis la dernière analyse (mi-ombre → plein soleil). Les
  conseils peuvent ne plus être à jour. » avec un bouton « Relancer l'analyse ». Pas de relance automatique : une
  analyse coûte, et une photo récente vaut mieux que celles d'avant le déménagement.
- **Relance guidée** : la remarque est pré-remplie (« La plante est passée de mi-ombre à plein soleil le 3 décembre »),
  les photos récentes sont proposées, et les nouvelles propositions passent par le flux existant (un bouton par
  proposition) : l'intervalle d'arrosage ne change que si l'utilisateur l'accepte.
- **Modifier un emplacement qui contient des plantes** : la confirmation dit combien de plantes sont concernées
  (« 3 plantes ; leurs analyses seront signalées à revoir »). Un simple changement de nom ne déclenche rien.
- **Vue d'ensemble** : dans Maison, un badge « 3 analyses à revoir » mène à la liste des plantes concernées, pour ne
  pas avoir à ouvrir chaque fiche.
- **Questions pour le propriétaire** : relancer plante par plante, ou proposer « relancer les 3 » d'un coup ? Une
  plante déplacée temporairement (rentrée pour l'hiver) doit-elle aussi être signalée ?
- **Impacts sur les données** : colonne `plant_analyses.context` (jsonb : emplacement, exposition, abri) ; la
  comparaison avec le lieu actuel se fait à l'affichage, sans état « à revoir » stocké.

### Impacts sur le modèle de données (à signaler, non implémentés)

- **1, 2, 5** : Aucun. Une requête qui charge `task: { subject: :location }` et un regroupement en Ruby (query object ou
  presenter).
- **3** : Colonne `tasks.importance` (`flexible` / `critical`, défaut `flexible`) ; clé `importance` dans le catalogue
  YAML.
- **4** : la marge se calcule depuis l'intervalle de la tâche ; pas de colonne tant que la règle suffit
  (`tasks.grace_days` nullable seulement si un réglage par tâche devient nécessaire).
- **6** : écarté, rien.
- **7** : `task_occurrences.postponed_from` (date d'origine) et l'auteur du report, pour afficher la trace sans
  confondre avec `skipped`.
- **Météo** : voir la section suivante.
- **8** : Réglage utilisateur `digest_scope` (`all` / `critical_only`).
- **Regroupement par domaine** : Méthode `domain` sur chaque type de sujet (`Plant` → `:plants`) pour l'icône et la
  couleur ; le contrat implicite d'un sujet (ADR 0010) passe de `household_id` + `name` à `+ domain`.

## Revue écran par écran

Sévérité : **B** bloquant (empêche un usage ou risque une perte), **I** important, **C** confort.

### Connexion (`sessions/new`)

- **I** · Déjà connecté, `/session/new` affiche le formulaire et l'en-tête connecté (cloche, « Se déconnecter ») en même
  temps
- **C** · Sur-titre « EASY HOME » en capitales espacées au-dessus de « Connexion » : redondant avec la barre native
- **C** · Pas de logo ni d'identité ; c'est le seul écran où la marque a sa place

### Créer un foyer (`households/new`)

- **C** · Message d'erreur dupliqué en dur au lieu de `shared/errors`
- **I** · Pas d'étape suivante guidée : on arrive sur un accueil vide « Mes plantes » sans proposer adresse ni
  emplacements

### Accueil (`home/show`)

- **I** · Mélange tâches du jour + inventaire complet + archivées ; titre « Mes plantes » faux à terme
- **I** · Une ligne par plante à arroser (6 lignes avec 8 plantes de démo dès le premier jour)
- **I** · Après « Arrosée », rechargement complet et flash en haut qui décale la liste sous le doigt
- **I** · Pas d'annulation immédiate d'une validation par erreur (il faut aller dans le journal de la plante)
- **I** · « + Ajouter une plante » sous la liste : hors écran dès 6 plantes
- **I** · Le nom du foyer en sur-titre est le seul accès au changement de foyer : non découvrable
- **C** · Deux bleus/verts pour les actions (sky « Arrosée », emerald « Ajouter »)
- **C** · « en retard de 1 j » en rouge gras pour un arrosage
- **C** · L'état vide « 🪴 » centré ne propose pas d'action dans la carte (le bouton est en dessous)
- **C** · Archivées en `<details>` en bas de l'accueil : à déplacer dans la liste du domaine

### Fiche plante (`plants/show`)

- **I** · 2,7 écrans, 26 éléments interactifs, six sections de même poids
- **I** · 18 cibles sous 44 px : « Modifier » 26 px, « Supprimer » 24 px, « Annuler » du journal 24 px, « ← Mes plantes
  » 17 px
- **I** · « Supprimer » une tâche collé à « Modifier », texte 12 px
- **I** · Modifier / Archiver / Supprimer la plante tout en bas
- **I** · Discussion IA complète et son formulaire dans la fiche
- **I** · Champ fichier natif (« Choose file / No file chosen », en anglais) + bouton séparé « Ajouter la photo » : deux
  gestes
- **C** · Pas de photo en en-tête : la plante n'a pas de visage, alors que le suivi photo existe
- **C** · « Fait » possible sur une tâche due dans 3 jours, sans indication de ce que ça change pour la suivante
- **C** · Journal : « 💧 Arrosée » répété ligne après ligne, sans auteur (utile dès qu'il y aura des membres)

### Analyse (`plants/analyses/_analysis`, `new`, `show`)

- **I** · Badge d'état « 👀 À surveiller » gris neutre : l'état le plus important de l'analyse n'a pas de couleur
- **C** · « Ajouter aux tâches » répété par action, boutons de tailles différentes (retour à la ligne)
- **C** · « ✓ Sur la fiche » / « ✓ En place » / « ✓ Dans les tâches » : trois mots pour « accepté »
- **C** · En attente : « ⏳ … La page se mettra à jour toute seule. » sans indicateur visuel ni durée
- **C** · Échec : message rouge + bouton, sans dire quoi faire si ça échoue encore
- **I** · Choix des photos (`new`) : case à cocher minuscule sous la vignette ; la vignette entière devrait être la
  cible

### Discussion (`analysis_questions/_thread`, `_form`)

- **C** · Bulles façon messagerie d'assistant : renforce l'effet « IA »
- **I** · Formulaire toujours ouvert sous l'analyse, même sans intention de poser une question
- **I** · Champ fichier natif en anglais

### Photo (`plants/photos/show`)

- **C** · Écran utile (date modifiable), mais « Supprimer la photo » isolé, sans menu
- **C** · Pas de navigation photo précédente / suivante (comparer l'évolution est le but du suivi)

### Ajouter / modifier une plante (`plants/new`, `_form`)

- **I** · La photo arrive après l'espèce : or la photo sert à **proposer** l'espèce
- **I** · Intervalle d'arrosage vide sans valeur par défaut ni aide (« combien de jours ? ») ; obligatoire
- **I** · Sept champs pour un ajout ; seul le nom est vraiment nécessaire au départ
- **C** · « Dernier arrosage » obligatoire de fait (date du jour par défaut) mais pas compris

### Tâche manuelle (`plants/tasks/_form`)

- **C** · Libellé « Tous les N jours après la dernière fois » : juste mais lourd
- Bon usage de `:has` sans JS, à garder (à garder)

### Ma maison (`households/edit`)

- **B** · « Supprimer » un emplacement **sans confirmation**, alors que ses plantes perdent leur emplacement
- **C** · Adresse, altitude et emplacements sur un seul écran long
- **I** · Pas de modification d'un emplacement (seulement supprimer et recréer)
- **I** · Accessible uniquement depuis l'accueil

### Mes foyers (`households/index`)

- **I** · Pas de retour web, pas de lien vers « Ma maison », pas d'indication de rôle
- **C** · Bouton « + Nouveau foyer » en pointillés verts : style différent de tous les autres boutons

### Notifications (`notification_settings/edit`)

- **C** · Case à cocher pour activer : un interrupteur est le contrôle attendu sur mobile
- **C** · L'heure se règle même si le résumé est désactivé
- **C** · « Téléphones » ne dit pas lequel est celui-ci
- **B (après refonte)** · Accès par 🔔 dans l'en-tête web, absent dans l'app une fois l'en-tête masqué : à prévoir dans
  Réglages

### Transverse

- **I** · Aucun `<title>` par page
- **I** · En-tête web doublé dans l'app ; « Se déconnecter » en un appui, sans confirmation
- **I** · Flashs en haut de page qui décalent le contenu
- **C** · Pas de thème sombre alors que la coque est `DayNight` (barre sombre, contenu clair)
- **C** · Pas d'indicateur de chargement sur les boutons (`button_to`) : double appui possible sur réseau lent
- **C** · Le dialogue de confirmation dit « Oui, confirmer » pour une suppression : le bouton devrait dire « Supprimer
  », en brique

## Liste exhaustive des changements

Effort : S (moins d'une demi-journée), M (une à deux journées), L (plus). Priorité : P1 (d'abord), P2, P3.

- **1. `households/edit`** : Confirmation avant de supprimer un emplacement. Pourquoi : Perte silencieuse du
  rattachement des plantes. Effort S, priorité P1.
- **2. Toutes les vues** : `content_for(:title)` sur chaque page. Pourquoi : Barre native « Easy Home » partout. Effort
  S, priorité P1.
- **3. `layouts/application`** : Masquer l'en-tête web si `hotwire_native_app?`. Pourquoi : Double barre dans l'app.
  Effort S, priorité P1.
- **4. Vues avec « ← … »** : Masquer les liens de retour web dans l'app. Pourquoi : Trois façons de revenir, dont une
  qui empile. Effort S, priorité P1.
- **5. `android_v1.json` + copie Android** : Règles modal / push / racines d'onglet, `/households` en modal. Pourquoi :
  Transitions et pile cohérentes. Effort S, priorité P1.
- **6. Contrôleurs de formulaires** : ~~`refresh_or_redirect_to` / `recede_or_redirect_to` après envoi~~. Vérifié dans
  le code de Hotwire Native Android 1.4.1 : une redirection vers l'écran d'en dessous ferme déjà la modal et recharge
  cet écran (`docs/android-coque.md`, 4.2). Rien à changer côté contrôleurs.
- **7. `MainActivity` + layout** : Barre d'onglets native : Aujourd'hui, Maison, Journal. Pourquoi : Navigation
  principale absente. Effort M, priorité P1.
- **8. Routes + contrôleurs** : Routes racines `/` (Aujourd'hui), `/maison`, `/journal`. Pourquoi : Une racine par
  onglet. Effort M, priorité P1.
- **9. Bridge `button` (Stimulus + Kotlin)** : Bouton d'action dans la barre native (+, Enregistrer). Pourquoi : Action
  principale toujours visible. Effort M, priorité P2.
- **10. Bridge `menu` (Stimulus + Kotlin)** : Menu ⋮ natif : Modifier, Archiver, Supprimer. Pourquoi : Actions rares
  hors du flux. Effort M, priorité P2.
- **11. `home/show`** : Accueil « Aujourd'hui » : En retard / Aujourd'hui / Bientôt, sans inventaire. Pourquoi : Un seul
  endroit pour le jour. Effort M, priorité P1.
- **12. Query object** : `TodayQuery` / presenter : regroupement par `template_key`, détail rangé par emplacement.
  Pourquoi : Une ligne par geste. Effort M, priorité P1.
- **13. Service** : `Tasks::CompleteMany` (transaction, résultat pour le toast). Pourquoi : Valider un groupe d'un
  geste. Effort M, priorité P1.
- **14. Vue + route** : Feuille « détail d'un groupe » avec cases à décocher. Pourquoi : Exception sans perdre la
  rapidité. Effort M, priorité P2.
- **15. Completions** : Réponse Turbo Stream : retire la ligne, toast en bas. Pourquoi : Pas de rechargement ni de
  décalage. Effort M, priorité P1.
- **16. Toast + Stimulus** : « Annuler » 5 s, appelle `CancelCompletion`. Pourquoi : Erreur de doigt réparable sur
  place. Effort M, priorité P1.
- **17. `layouts/_flash`** : Flashs en toast bas, superposés, sans décalage. Pourquoi : Contenu stable sous le doigt.
  Effort S, priorité P2.
- **18. `DueLabelComponent`** : Libellés calmes ; rouge seulement si « à ne pas rater ». Pourquoi : Moins de
  culpabilité. Effort S, priorité P2.
- **19. Migration + catalogue** : `tasks.importance` (flexible / critical). Pourquoi : Hiérarchiser sans tout mettre en
  rouge. Effort M, priorité P2.
- **20. Domaine** : marge proportionnelle à l'intervalle (25 %, de 0 à 3 jours), lue par le futur job `missed`.
  Pourquoi : Tolérance des tâches souples. Effort M, priorité P2.
- **21. `Notifications::SendDigest`** : Résumé groupé (« arroser 4 plantes »). Pourquoi : Notification lisible.
  Effort S, priorité P2.
- **22. Réglages notifications** : Option « Seulement ce qui ne doit pas être raté ». Pourquoi : Calme choisi. Effort S,
  priorité P3.
- **23. Météo (ADR)** : job du soir, adaptateur Open-Meteo, arrosage noté fait par la pluie pour les emplacements non
  abrités (remplace le rythme par emplacement, écarté). Pourquoi : Moins de tâches inutiles. Effort L, priorité P2.
- **24. Ligne de tâche** : Action « Demain » (décaler), tracée dans le journal (`postponed_from`). Pourquoi :
  Alternative au rouge. Effort M, priorité P3.
- **25. `app/assets/stylesheets`** : Jetons de couleur (`@theme` Tailwind 4) : papier, encre, sapin, brique, domaines.
  Pourquoi : Identité propre, cohérence. Effort S, priorité P1.
- **26. `fr.yml`** : Retirer tous les emojis de l'interface. Pourquoi : Effet « IA », rendu inégal. Effort S, priorité
  P1.
- **27. `IconComponent` + SVG Lucide** : Jeu d'icônes au trait unique. Pourquoi : Remplace les emojis. Effort M,
  priorité P1.
- **28. Composants** : `TaskRowComponent`, `ListGroupComponent`, `EmptyStateComponent`, `ButtonComponent`. Pourquoi : UI
  réutilisée, une seule source de style. Effort M, priorité P1.
- **29. Toutes les vues** : Listes à filets au lieu de cartes ombrées. Pourquoi : Hiérarchie lisible. Effort M, priorité
  P2.
- **30. Toutes les vues** : Une seule couleur d'action ; boutons 48 px ; cibles ≥ 44 px. Pourquoi : Accessibilité,
  cohérence. Effort M, priorité P1.
- **31. Écran Maison (nouveau)** : Inventaire par domaine (Plantes, puis autres), lieux de la maison. Pourquoi : Accueil
  soulagé, place pour les domaines. Effort M, priorité P1.
- **32. Liste Plantes (nouveau)** : Liste par emplacement avec prochaine échéance, archivées en filtre. Pourquoi :
  Inventaire dédié. Effort M, priorité P2.
- **33. `plants/show`** : En-tête (photo, nom, espèce, lieu) + prochaine action + onglets Soins / Photos / Historique.
  Pourquoi : Fiche courte et hiérarchisée. Effort L, priorité P2.
- **34. `plants/show`** : Analyse résumée en carte « État » ; détail et discussion sur leur page. Pourquoi :
  Désencombrer la fiche. Effort M, priorité P2.
- **35. `plants/show`** : Ajout de photo en un geste (bouton qui ouvre l'appareil, envoi auto). Pourquoi : Deux gestes
  et champ anglais. Effort S, priorité P2.
- **36. `plants/_form`** : Ajout rapide : photo en premier, nom, emplacement ; arrosage pré-rempli (7 j). Pourquoi :
  Moins de champs, l'IA propose le reste. Effort M, priorité P2.
- **37. Champs fichier** : Composant de sélection de fichier en français (label stylé, nom du fichier). Pourquoi : «
  Choose file » en anglais. Effort S, priorité P2.
- **38. `analyses/_analysis`** : État en couleur (sapin / ocre / brique) avec icône. Pourquoi : L'information clé de
  l'analyse. Effort S, priorité P2.
- **39. `analyses/_analysis`** : Un seul libellé « Ajouté » pour les propositions acceptées. Pourquoi : Vocabulaire
  unique. Effort S, priorité P3.
- **40. `analyses/new`** : Vignette entière cliquable, coche en surimpression. Pourquoi : Cible tactile. Effort S,
  priorité P3.
- **41. `analysis_questions`** : Discussion repliée derrière « Poser une question » ; style fil de notes, pas bulles.
  Pourquoi : Moins « chat IA ». Effort S, priorité P3.
- **42. `photos/show`** : Photo précédente / suivante ; supprimer dans le menu ⋮. Pourquoi : Comparer l'évolution.
  Effort M, priorité P3.
- **43. Journal (nouveau)** : Onglet Journal : tous domaines, filtre, auteur, annuler. Pourquoi : Historique centralisé.
  Effort M, priorité P2.
- **44. Réglages (nouveau)** : Page Réglages : compte, notifications, foyers, membres, déconnexion confirmée. Pourquoi :
  Réglages hors des onglets. Effort M, priorité P1.
- **45. `notification_settings`** : Interrupteur, heure désactivée si résumé coupé, « ce téléphone ». Pourquoi :
  Contrôles attendus. Effort S, priorité P3.
- **46. `households/index`** : En modal, avec rôle et accès à « Lieux de la maison ». Pourquoi : Choix du foyer
  cohérent. Effort S, priorité P2.
- **47. `households/edit`** : Séparer Adresse et Emplacements ; modifier un emplacement (nom, exposition, abri).
  Pourquoi : Écrans plus courts ; aujourd'hui il faut recréer l'emplacement et y déplacer chaque plante. Effort M,
  priorité P2. Va avec #57 (analyses à revoir).
- **48. `households/new`** : Après création : proposer adresse puis premier emplacement (2 étapes passables). Pourquoi :
  Démarrage guidé. Effort M, priorité P3.
- **49. `sessions/new`** : Rediriger si déjà connecté ; logo (`docs/maquettes/v2/logo.html`) ; sans sur-titre.
  Pourquoi : Écran propre. Effort S, priorité P3.
- **50. `shared/_confirm_dialog`** : Libellé et couleur du bouton selon l'action (« Supprimer » en brique). Pourquoi :
  Confirmation explicite. Effort S, priorité P2.
- **51. `button_to`** : État « en cours » visible. Turbo désactive déjà le bouton pendant l'envoi ; un style sur
  `form[aria-busy]` le grise (fait en PR 1). Libellé « en cours » (`data-turbo-submits-with`) seulement si le besoin
  se confirme. Pourquoi : Double appui. Effort S, priorité P2.
- **52. Android** : Couleurs de la coque alignées sur les jetons (barre, onglets). Pourquoi : Cohérence natif / web.
  Effort S, priorité P2.
- **53. CSS + coque** : Thème sombre à partir des jetons. **Plus tard** ; en attendant, la coque passe en thème clair
  fixe pour ne pas afficher une barre sombre sur un contenu clair. Les jetons en variables CSS le rendront simple.
  Effort M, priorité P3.
- **54. `docs/maquettes`** : Maquettes v1 supprimées dans cette PR. Pourquoi : Éviter de réintroduire dégradés et
  emojis. Fait.
- **55. `docs/tests.md`** : Parcours critiques : valider un groupe, annuler, naviguer par onglets. Pourquoi : Les tests
  sont la preuve. Effort S, priorité P1.
- **56. Mise en page large** : sur ordinateur (≥ 768 px), la barre d'onglets web devient une colonne latérale et
  les listes passent à une largeur de lecture (≈ 640 px). Pourquoi : l'usage navigateur reste important pour faire
  tester l'app facilement. Effort M, priorité P2.
- **57. Analyses et changement de lieu** : signaler qu'une analyse a été faite dans un autre lieu (voir « Changement
  d'emplacement et analyses »). Pourquoi : un conseil donné pour la mi-ombre ne vaut plus en plein soleil. Effort M,
  priorité P2. À concevoir avec le propriétaire avant la PR 6.

## Découpage en PR

Chaque PR est livrable seule, testée (system specs sur les parcours touchés) et ne casse pas l'existant.

1. **PR 1 · Correctifs rapides** (#1, #2, #50, #51) : confirmation de suppression d'emplacement, titres de page,
   libellés de confirmation, anti double appui. Aucun changement visuel majeur.
2. **PR 2 · Coque sans doublons** (#3, #4, #5, #6) : en-tête web masqué dans l'app, liens retour masqués, path
   configuration revue, formulaires qui se ferment. Le ressenti « transitions » change déjà.
3. **PR 3 · Jetons et icônes** (#25, #26, #27, #52, fait) : palette en `@theme`, `IconComponent`, retrait des emojis de
   `fr.yml`, couleurs de la coque. Les écrans gardent leur structure.
4. **PR 4 · Composants de base** (#28, #29, #30, #17, #18, fait) : ligne de tâche, groupe de liste, état vide, bouton,
   toast ; appliqués à l'accueil et à la fiche sans les restructurer.
5. **PR 5 · Aujourd'hui groupé** (#11, #12, #13, #15, #16, #55) : regroupement, validation groupée, toast Annuler. Le
   cœur de la remarque 1.
6. **PR 6 · Maison, Journal, Réglages** (#8, #31, #32, #43, #44, #46, #47, #57) : les trois racines web, prêtes
   pour les onglets (dans le navigateur, une barre d'onglets web en bas les remplace).
7. **PR 7 · Onglets natifs** (#7) : la coque passe à trois navigateurs.
8. **PR 8 · Bridge bouton et menu** (#9, #10) : + et ⋮ natifs.
9. **PR 9 · Fiche plante allégée** (#33, #34, #35, #37, #38, #41) et **ajout rapide** (#36).
10. **PR 10 · Importance et tolérance** (#19, #20, #21, #22, #24) : marge proportionnelle, report tracé, catalogue,
    résumé groupé. À faire avec le deuxième domaine (poubelles), où la différence souple / à ne pas rater devient
    concrète.
11. **PR 11 · Arrosage et météo** (#23) : ADR, adaptateur Open-Meteo, job du soir, arrosage noté par la pluie.

La mise en page large (#56) se fait avec la PR 6 (la colonne latérale remplace la barre d'onglets web sur ordinateur).
Les invités sont hors de ce lot : ils auront leur propre lot, avec leurs onglets.

Ensuite, au fil de l'eau : #14, #39, #40, #42, #45, #47, #48, #49, #53, #54.

## Décisions du propriétaire (21 novembre 2026)

1. **Onglets** : trois onglets natifs, Aujourd'hui, Maison, Journal.
2. **Regroupement** : tout l'arrosage du jour sur une ligne (« Arroser · 4 »), le détail rangé par emplacement.
3. **Rythme par emplacement** : non. Chaque plante garde son rythme (#23 devient la météo).
4. **Tolérance** : marge proportionnelle à la fréquence (25 %, de 0 à 3 jours), et la pluie compte comme un arrosage
   pour les emplacements non abrités (section « Arrosage et météo »).
5. **Décaler** : laisse une trace discrète dans le journal, sans compter comme fait ni manqué (choix délégué, motivé
   dans le mécanisme 7).
6. **Identité** : palette « carnet de maison » validée. Logo et icône proposés : `docs/maquettes/v2/logo.html`.
7. **Invités** : hors de ce lot.
8. **Thème sombre** : plus tard ; la coque passe en thème clair fixe d'ici là.
9. **Ordinateur** : oui, l'usage reste important pour faire tester l'app ; mise en page large (#56).
10. **Maquettes v1** : supprimées dans cette PR.