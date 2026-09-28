# 0003. Solid Queue plutôt que Redis / Sidekiq

- Statut : acceptée
- Date : 2026-09-28

## Contexte

L'app a besoin de jobs de fond (envoi des rappels, relances, calcul des échéances manquées, plus tard appels IA) et d'un planificateur qui s'exécute toutes les minutes. Le volume se compte en dizaines de jobs par jour.

## Décision

Solid Queue (file stockée en base), avec les tâches récurrentes déclarées dans `config/recurring.yml`. Solid Cache et Solid Cable pour le cache et Action Cable. En production, Solid Queue tourne dans Puma (`SOLID_QUEUE_IN_PUMA`). Tableau de bord possible avec `mission_control-jobs`.

## Alternatives écartées

- **Sidekiq + Redis** : éprouvé et performant, mais un service de plus à déployer et surveiller, sans bénéfice à ce volume.

## Conséquences

- Aucune infrastructure en plus de la base de données.
- Si le volume ou la latence deviennent un problème (peu probable), sortir Solid Queue de Puma vers un processus `bin/jobs` dédié.
