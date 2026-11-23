# 0016. Un modèle par domaine qui calcule, un équipement générique pour le reste

- Statut : acceptée
- Date : 2026-11-23
- Amende : 0010

## Contexte

L'ADR 0010 prévoyait un modèle et une table par type d'élément (`Plant`, puis `Pool`, `Dishwasher`…), chacun avec
ses colonnes typées, pour éviter un `Item` générique à jsonb sans contraintes. Elle supposait que chaque type aurait
des attributs que l'app exploite (volume d'une piscine, cycles d'un lave-vaisselle, récurrence basée sur l'usage).

La conception des autres domaines (`docs/conception/equipements-et-taches.md`) a tranché autrement côté produit : un
équipement (piscine, lave-vaisselle, chauffe-eau, clim, voiture…) est un objet qu'on **entretient**, l'app se contente
d'en rappeler les tâches. Il a un nom, un type, des notes « À savoir », des photos et des tâches qui portent leur
« Comment faire ». Aucun champ propre à un type n'est lu par l'app : la récurrence basée sur l'usage est hors v1, une
marque ou une garantie tiennent dans les notes et une photo de la plaque. Les poubelles ne sont pas un objet : ce
sont des tâches de la maison, sans sujet.

Une table par type donnerait des tables identiques (`pools`, `dishwashers`, `water_heaters`…) et une migration à
chaque nouvel objet.

## Décision

- **Un modèle par domaine qui calcule** : un domaine dont l'app exploite les attributs a son modèle et sa table
  (`Plant` : espèce, arrosage, analyse IA, pluie ; plus tard `Pet`). L'ADR 0010 reste valable pour eux.
- **Un modèle générique `Equipment`** pour tout ce que l'app se contente de rappeler : `household_id` (lecture
  seule), `kind` (liste du catalogue, dont « Autre » pour un équipement personnalisé), `name`, `notes` (« À savoir »).
  **Pas de jsonb `properties`.** Un champ propre à un type n'arrive qu'avec la fonction qui le lit : colonne nullable
  validée selon le type, ou table 1-1 `<type>_details`, décidé par ADR à ce moment-là.
- **Catalogue** des types d'équipements et de leurs tâches suggérées dans `config/catalogue.yml`, textes en I18n
  (`config/locales/catalogue.fr.yml`), pas de table. Une suggestion est **copiée** dans la tâche à sa création :
  titre, rythme, importance, Comment faire, tout reste modifiable. `tasks.suggestion_key` garde l'origine, sans
  comportement. Le catalogue s'enrichit par une PR.
- `Task#subject` reste polymorphe : `Plant`, `Equipment`, ou nul (tâche de la maison). **`Photo#subject` devient
  polymorphe** de la même façon (`Plant`, `Equipment`, `Task` pour les photos d'une tâche) ; la clé étrangère
  `photos.plant_id` disparaît, remplacée par des validations comme pour `tasks.subject`.
- **Contrat d'un sujet**, vérifié par une spec partagée : `household_id` (lecture seule), `name`, `archived?`,
  `tasks` et `photos` (`dependent: :destroy`), `face` (photo d'en-tête).
- `template_key` reste réservé aux tâches **gérées par leur sujet** (`plant.watering`, réglée depuis la plante).
- La gem `ice_cube`, prévue pour la récurrence fixe et jamais utilisée, est retirée : l'arithmétique de
  `Recurrence::Fixed` (une ancre, un pas de N semaines ou N ans) est simple.

## Alternatives écartées

- **Une table par type d'équipement** (ADR 0010 telle quelle) : tables identiques, une migration par objet, rien à y
  mettre de propre au type.
- **`Item` générique avec `properties` jsonb** : déjà écarté par l'ADR 0010 ; inutile tant qu'aucun attribut n'est lu.
- **Catalogue en base** (modèles de tâches éditables dans l'app) : pas de besoin en v1 ; une tâche copiée se modifie
  déjà librement. À reconsidérer si l'on veut enregistrer ses propres modèles.
- **Un objet « consigne » séparé, lié aux tâches** : une indirection et un appui de plus pour un cas rare (deux tâches
  avec la même consigne). Une consigne seulement à relire est une tâche « quand il le faut ».

## Conséquences

- Ajouter un type d'équipement = quelques lignes de catalogue et de textes, sans migration.
- Un équipement n'a pas d'archivage en v1 : seulement la suppression, qui efface ses tâches et son historique.
- Les photos d'une plante perdent leur clé étrangère : la cohérence (photo d'une analyse, couverture) passe par des
  validations. Migration en deux temps (colonnes polymorphes remplies, puis `plant_id` supprimée).
- `docs/domaine.md` décrit `Equipment` et les tâches de la maison au fil des PR.