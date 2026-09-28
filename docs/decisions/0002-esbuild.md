# 0002. esbuild pour le JavaScript

- Statut : acceptée
- Date : 2026-09-28

## Contexte

Avec Hotwire, le JavaScript se limite à des contrôleurs Stimulus et des bridge components. On veut pouvoir tester ce JS (Vitest), donc disposer d'un `package.json` et de l'écosystème npm.

## Décision

`jsbundling-rails` avec esbuild. Tailwind 4 via `cssbundling-rails`. Assets servis par Propshaft.

## Alternatives écartées

- **Vite (`vite_ruby`)** : rechargement à chaud et bon écosystème, mais second serveur de développement, manifeste et configuration en plus. Justifié seulement pour un front riche.
- **importmap** (défaut Rails 8) : pas d'étape de build, mais tests JS avec des paquets npm laborieux.

## Conséquences

- `bin/dev` lance trois processus (web, js, css).
- Pas de rechargement à chaud : acceptable vu le volume de JS.
- Node et Yarn requis en développement et dans l'image Docker.
