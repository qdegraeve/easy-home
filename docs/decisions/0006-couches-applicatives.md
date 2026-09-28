# 0006. Couches applicatives

- Statut : acceptée
- Date : 2026-09-28

## Contexte

On veut une app bien construite, lisible par un humain et testable, sans tomber dans la surenchère d'abstraction.

## Décision

On garde le MVC comme base, et on ajoute des couches **uniquement quand le besoin existe** :

- **Services** avec `dry-monads` (Result + do notation) pour les cas d'usage multi-modèles ou avec effets de bord.
- **Formulaires / contrats** : `ActiveModel::Validations` + `SimpleDelegator`.
- **Query objects** pour les requêtes réutilisées ou complexes.
- **Policies** avec Pundit : foyer partagé et invités aux droits restreints.
- **Composants** ViewComponent pour l'UI réutilisable ; partials pour le reste.
- **Domaine pur** (`app/domain`) pour le moteur de récurrence.

Règles d'usage et exemples dans `docs/architecture.md`.

## Alternatives écartées

- **`dry-validation`** pour les contrats : puissant, mais s'intègre mal avec `form_with` et les messages d'erreur Rails.
- **Query sets / resource objects** : une couche de trop pour la taille du projet. À reconsidérer si les query objects prolifèrent.
- **ActionPolicy** : très bien pour le scoping et les tests, mais Pundit est plus simple et suffit.
- **Tout dans les modèles** (« Rails omakase » strict, concerns) : moins de fichiers, mais la logique des effets de bord se disperse dans des callbacks difficiles à tester.

## Conséquences

- Plus de fichiers qu'une app Rails minimaliste, compensés par une convention claire du « où va quoi ».
- Tout nouveau code suit ces règles ; toute exception est justifiée dans la revue ou dans un ADR.
