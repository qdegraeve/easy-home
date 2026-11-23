# 0010. Un modèle par type d'élément, tâches rattachées par un sujet polymorphe

- Statut : acceptée, amendée par 0016 (équipements)
- Date : 2026-11-19

## Contexte

Le modèle de domaine initial prévoyait un `Item` générique (`kind` + attributs dans un `properties` jsonb) pour tout ce
que possède le foyer : plante, piscine, lave-vaisselle, animal. Ces types ont des attributs et des comportements très
différents (espèce, photos et analyse IA pour une plante ; volume et mesures pour une piscine ; cycles et sel pour un
lave-vaisselle). Un `Item` générique accumulerait du jsonb sans contraintes, des validations conditionnelles par type
et des requêtes peu lisibles.

Ce qui est vraiment commun, ce sont les **tâches** : récurrence, « Fait », journal, notifications.

## Décision

- **Un modèle et une table par type** : `Plant` aujourd'hui, `Pool`, `Dishwasher`… plus tard. Chaque type a ses
  colonnes typées, ses validations et ses services (`Plants::Add`, `Plants::Archive`…).
- **`Task` appartient toujours à un foyer** (`household_id`, obligatoire) : c'est par lui que passent les droits
  (`policy_scope`) et les listes (échéances du jour, tableau de bord). Elle peut se rattacher à un **sujet
  polymorphe** optionnel (`subject_type` / `subject_id`) : la plante arrosée, plus tard la piscine. Une tâche manuelle
  n'a pas de sujet.
- Le code des tâches (`Task`, `TaskOccurrence`, `Recurrence`, `Tasks::Complete`) ne lit jamais son sujet : il reste
  générique. Le sujet sert à l'affichage, à la fiche du sujet (`plant.tasks`), à la suppression en cascade et au
  comportement propre au type (intervalle proposé par l'IA pour l'arrosage).
- **Cohérence du foyer**, garantie côté Rails :
  - `household_id` en lecture seule (`attr_readonly`) sur `Task` et sur chaque type de sujet ;
  - validation sur `Task` : le sujet, s'il existe, est du même foyer ;
  - les tâches ne sont créées que par les services, qui prennent le foyer du sujet.
- Un sujet peut être **archivé** (`archived_at`) : ses tâches sont désactivées et leur échéance ouverte supprimée,
  le journal reste. La suppression reste possible et efface l'historique.
- Contrat implicite d'un sujet : répondre à `household_id` et `name`. À vérifier par une spec partagée quand le
  deuxième type arrivera.

## Alternatives écartées

- **`Item` générique avec `properties` jsonb** : modèle fourre-tout, pas de contraintes en base sur les attributs.
- **`delegated_type`** (`items` commun + table par type) : utile pour une liste commune à tous les types avec tri et
  pagination, ce dont on n'a pas besoin (le tableau de bord liste des échéances, pas des éléments). Deux
  enregistrements par élément, formulaires imbriqués, et c'est aussi du polymorphisme (`itemable_type`).
- **Colonnes exclusives** (`plant_id`, `pool_id`… avec `CHECK` et clé étrangère composite incluant `household_id`) :
  garantie en base, même en SQL brut, mais une colonne et une contrainte par type et une méthode `subject` à écrire.
  À reconsidérer si un import de masse ou des écritures hors de l'app apparaissent.

## Conséquences

- Ajouter un type d'élément = une table, un modèle, `has_many :tasks, as: :subject, dependent: :destroy`, ses services.
- Un écart de foyer entre une tâche et son sujet n'est possible que par une écriture hors de l'app (console, SQL).
- Un inventaire commun à tous les types demandera une requête par type, ou une table `items` ajoutée à ce moment-là.
