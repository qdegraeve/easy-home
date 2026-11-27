# Produit

## Problème

Certaines tâches domestiques sont trop rares pour devenir des habitudes et trop fréquentes pour qu'on y pense comme à un événement : poubelle jaune une semaine sur deux, sel du lave-vaisselle, filtre de la clim, vermifuge du chat…

Un rappel récurrent de calendrier ne suffit pas :

- un rappel ignoré disparaît, alors qu'une tâche doit rester ouverte tant qu'elle n'est pas faite ;
- il ne connaît pas le contexte de la maison (équipements, animaux, membres du foyer) ;
- il ne garde aucune trace de ce qui a été fait, par qui et quand.

Surtout, la connaissance de la maison reste dans la tête de celui qui fait la tâche d'habitude : quel jour sortir
quelle poubelle, quel produit mettre dans la piscine, où est le filtre de la clim. Quand il est absent, personne ne
sait faire. L'objectif d'Easy Home est que **toute la connaissance de la maison soit partagée par les membres du
foyer** ; ne pas oublier les tâches en est une fonction essentielle.

Les plantes cumulent tous ces problèmes : l'arrosage dépend de chaque espèce et de la saison, et on ne voit un problème
(maladie, parasite, manque d'eau) que lorsqu'il est déjà avancé. C'est le besoin initial et la **première priorité**.

## Proposition

1. **Rappeler au bon moment** : la veille au soir pour les poubelles, avec relance tant que ce n'est pas fait.
2. **Valider en un geste** : bouton « Fait » directement dans la notification.
3. **Garder un journal** : historique des tâches faites, sautées ou manquées.
4. **Partager le foyer** : plusieurs membres qui voient tous les mêmes tâches, avec leur « Comment faire » et leurs
   notes « À savoir », et des invités aux droits restreints (pet-sitter, voisin pendant les vacances).
5. **Démarrer vite** : déclarer ses équipements génère les tâches d'entretien associées.

## Concepts clés

Conception détaillée, validée le 23 novembre 2026 : `docs/conception/equipements-et-taches.md`.

- **Plante** : un domaine dont l'app exploite les attributs (espèce, arrosage, analyse, pluie).
- **Équipement** : ce qu'on entretient (piscine, lave-vaisselle, chauffe-eau, clim, voiture, « Autre »), avec un nom,
  un type, des notes « À savoir » et des photos. L'app en rappelle les tâches, sans champ propre à un type.
- **Tâche** : rattachée à une plante, à un équipement, ou à rien (**tâche de la maison** : les poubelles). Elle porte
  son **Comment faire**, lu au moment de la faire, et peut avoir ses photos.
- **Suggestion** : une tâche toute prête du catalogue (poubelles, filtre du lave-vaisselle…), copiée puis modifiable.
- **Rythmes** : une fois ; tous les N jours, semaines, mois ou ans **après la dernière fois** ; **à jour fixe** (un
  mardi sur deux, chaque année le 1er novembre) ; **quand il le faut** (le sel : sans échéance, avec la dernière
  fois). Chaque rythme se change en modifiant la tâche. La récurrence basée sur l'usage (cycles, km) est pour plus
  tard.
- **Rappel** : à une heure le jour de l'échéance, relancé pour les tâches « à ne pas rater ».

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

- Tâches de la maison et poubelles, récurrence à jour fixe, rappels à une heure et relances
- Équipements, « quand il le faut », suggestions : piscine, lave-vaisselle, chauffe-eau
- Notifications push sur Android, avec validation depuis la notification
- Un animal (domaine qui calcule, comme les plantes)
- Journal des tâches (faites, reportées, manquées)
- Foyer partagé (membres) et invités limités à certaines tâches

## Hors MVP (idées pour plus tard)

- **Tournantes** et attribution automatique des tâches.
- **Récurrence basée sur l'usage** (cycles, kilomètres), proposée depuis l'historique des « Fait ».
- **Modèles de tâches personnels**, enregistrés depuis l'app.
- **Plantes, au-delà de la première version** : fiche d'entretien complète, rempotage et engrais, arrosage ajusté par la
  météo (pluie).
- **Stocks de consommables** (croquettes, chlore, filtres), avec rappel d'achat.
- **Relevés de mesures** (pH et chlore de la piscine, poids d'un animal) avec courbes.
- **Déclencheurs contextuels** : géolocalisation, tag NFC.
- **Mode cyclone** : checklist de préparation.
- Import du calendrier de collecte des déchets de la commune.
- Mode vacances, export du journal (carnet d'entretien).
