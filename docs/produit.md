# Produit

## Problème

Certaines tâches domestiques sont trop rares pour devenir des habitudes et trop fréquentes pour qu'on y pense comme à un événement : poubelle jaune une semaine sur deux, sel du lave-vaisselle, filtre de la clim, vermifuge du chat…

Un rappel récurrent de calendrier ne suffit pas :

- un rappel ignoré disparaît, alors qu'une tâche doit rester ouverte tant qu'elle n'est pas faite ;
- il ne connaît pas le contexte de la maison (équipements, animaux, membres du foyer) ;
- il ne garde aucune trace de ce qui a été fait, par qui et quand.

Les plantes cumulent tous ces problèmes : l'arrosage dépend de chaque espèce et de la saison, et on ne voit un problème
(maladie, parasite, manque d'eau) que lorsqu'il est déjà avancé. C'est le besoin initial et la **première priorité**.

## Proposition

1. **Rappeler au bon moment** : la veille au soir pour les poubelles, avec relance tant que ce n'est pas fait.
2. **Valider en un geste** : bouton « Fait » directement dans la notification.
3. **Garder un journal** : historique des tâches faites, sautées ou manquées.
4. **Partager le foyer** : plusieurs membres, et des invités aux droits restreints (pet-sitter, voisin pendant les vacances).
5. **Démarrer vite** : déclarer ses équipements génère les tâches d'entretien associées.

## Concepts clés

- **Élément** : ce que possède le foyer (lave-vaisselle, piscine, chat, clim…), avec des attributs propres (fréquence d'usage, volume…).
- **Modèle de tâche** : défini dans un catalogue et rattaché à un type d'élément. Il calcule la récurrence à partir des attributs de l'élément.
  - Exemple : lave-vaisselle à 5 cycles par semaine et réservoir de sel d'environ 40 cycles, soit une tâche « remettre du sel » environ toutes les 8 semaines.
- **Tâche** : créée depuis un modèle ou manuellement. Les deux passent par le même modèle de données, seule l'origine diffère.
- **Types de récurrence** :
  - **fixe** : toutes les 2 semaines le mardi, le 1er du mois… ;
  - **glissante** : X jours après la dernière réalisation ;
  - **basée sur l'usage** : l'intervalle est calculé depuis la capacité et le rythme d'usage, puis recalibré. Exemple : à la validation, « le voyant était-il allumé ? » ; si oui, l'intervalle raccourcit.

## Première version : les plantes

Point de départ : une dizaine de plantes en extérieur, à La Réunion.

1. **Ma maison** : l'adresse, saisie avec autocomplétion. L'app en déduit la position et l'altitude, sans rien
   demander d'autre (le climat varie beaucoup d'un quartier à l'autre de l'île, y compris dans une même commune). Puis
   la liste des emplacements (« terrasse », « jardin devant »…) avec leur exposition au soleil et leur abri du vent.
   L'IA en tient compte pour l'arrosage et le diagnostic.
2. **Inventaire** : chaque plante a un nom, une espèce, un emplacement et des photos.
3. **Identification** : la première photo propose l'espèce automatiquement ; on la confirme ou on la corrige.
4. **Arrosage** : chaque plante a son intervalle d'arrosage (récurrence glissante). L'IA propose l'intervalle de départ
   selon l'espèce et le climat ; on le valide ou on l'ajuste. Un bouton « J'ai arrosé » alimente le journal.
5. **Suivi photo** : un historique de photos par plante pour voir l'évolution.
6. **Analyse** : sur une photo, un bouton « Analyser » donne l'état (bien / à surveiller / à traiter), ce qui est observé
   et les actions conseillées. Une action peut devenir une tâche si on l'accepte.

Foyer minimal (créé à l'inscription), sans invités ni rôles. Pas encore de notifications : l'app s'utilise depuis le
navigateur, sur téléphone comme sur ordinateur (mise en page mobile d'abord, élargie sur grand écran). Le choix du
modèle d'IA est dans l'ADR 0008.

## Ensuite (MVP complet)

- Éléments et modèles de tâches. Catalogue minimal : poubelles, lave-vaisselle, piscine, un animal
- Tâches manuelles
- Récurrences fixes et basées sur l'usage (la glissante arrive avec les plantes)
- Notifications push avec validation depuis la notification et relance
- Journal des tâches (faites, sautées, manquées)
- Foyer partagé (membres) et invités limités à certaines tâches

## Hors MVP (idées pour plus tard)

- **Tournantes** et attribution automatique des tâches. La colonne `assignee` est prévue dès le MVP, optionnelle.
- **Plantes, au-delà de la première version** : fiche d'entretien complète, rempotage et engrais, arrosage ajusté par la
  météo (pluie).
- **Stocks de consommables** (croquettes, chlore, filtres), avec rappel d'achat.
- **Relevés de mesures** (pH et chlore de la piscine, poids d'un animal) avec courbes.
- **Déclencheurs contextuels** : géolocalisation, tag NFC.
- **Mode cyclone** : checklist de préparation.
- Import du calendrier de collecte des déchets de la commune.
- Mode vacances, export du journal (carnet d'entretien).
