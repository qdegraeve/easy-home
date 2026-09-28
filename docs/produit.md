# Produit

## Problème

Certaines tâches domestiques sont trop rares pour devenir des habitudes et trop fréquentes pour qu'on y pense comme à un événement : poubelle jaune une semaine sur deux, sel du lave-vaisselle, filtre de la clim, vermifuge du chat…

Un rappel récurrent de calendrier ne suffit pas :

- un rappel ignoré disparaît, alors qu'une tâche doit rester ouverte tant qu'elle n'est pas faite ;
- il ne connaît pas le contexte de la maison (équipements, animaux, membres du foyer) ;
- il ne garde aucune trace de ce qui a été fait, par qui et quand.

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

## Périmètre du MVP

- Éléments et modèles de tâches. Catalogue minimal : poubelles, lave-vaisselle, piscine, un animal
- Tâches manuelles
- Récurrences fixes, glissantes et basées sur l'usage
- Notifications push avec validation depuis la notification et relance
- Journal des tâches (faites, sautées, manquées)
- Foyer partagé (membres) et invités limités à certaines tâches

## Hors MVP (idées pour plus tard)

- **Tournantes** et attribution automatique des tâches. La colonne `assignee` est prévue dès le MVP, optionnelle.
- **Module plantes avec IA** :
  - une photo permet l'identification (Pl@ntNet ou un modèle de vision) ;
  - un LLM génère une fiche d'entretien en JSON structuré, adaptée au climat réunionnais ;
  - des tâches sont proposées puis validées par l'utilisateur ;
  - un diagnostic est possible sur nouvelle photo.

  Clé API fournie par l'utilisateur (« bring your own key »), stockée chiffrée avec `encrypts`, derrière une couche d'abstraction du fournisseur.
- **Stocks de consommables** (croquettes, chlore, filtres), avec rappel d'achat.
- **Relevés de mesures** (pH et chlore de la piscine, poids d'un animal) avec courbes.
- **Déclencheurs contextuels** : météo (reporter l'arrosage), géolocalisation, tag NFC.
- **Mode cyclone** : checklist de préparation.
- Import du calendrier de collecte des déchets de la commune.
- Mode vacances, export du journal (carnet d'entretien).
