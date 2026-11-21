# 0013. Identité visuelle : palette en jetons Tailwind et icônes Lucide copiées

- Statut : acceptée
- Date : 2026-11-21

## Contexte

La revue UX (`docs/ux/revue-ux.md`) a relevé un thème « trop IA » : emojis dans presque tous les titres, couleurs
Tailwind génériques et deux couleurs d'action concurrentes (vert pour ajouter, bleu pour « Arrosée »). Le propriétaire
a validé la palette « carnet de maison » et le logo (`docs/maquettes/v2/logo.html`).

## Décision

- **Palette en jetons** dans `app/assets/stylesheets/application.tailwind.css` (`@theme` de Tailwind 4) : `paper`,
  `surface`, `subtle`, `line`, `ink`, `muted`, `action`, `alert`, `warn` et une couleur par domaine. Les vues utilisent
  ces classes (`bg-paper`, `text-ink`, `bg-action`…), plus les couleurs génériques (`stone`, `emerald`, `sky`, `red`).
  Une seule couleur d'action, le vert sapin ; la brique seulement pour ce qui ne doit pas être raté.
- **Icônes Lucide** (licence ISC) au trait, **copiées** dans `app/assets/images/icons/` depuis `lucide-static` (version
  dans l'en-tête de chaque fichier, licence à côté), et dessinées inline par `IconComponent` (helper `icon`) pour
  prendre la couleur du texte. On ajoute un fichier pour une nouvelle icône ; une spec vérifie que toutes les icônes
  utilisées existent.
- **Plus d'emoji dans l'interface** (`config/locales/fr.yml`, vues) ; ils restent possibles dans le contenu saisi.
- **Logo** : un toit et une coche. `public/icon.svg` et `public/icon.png` pour le web, icône adaptative (avec version
  monochrome pour les icônes à thème) dans la coque Android, dont les couleurs reprennent les mêmes valeurs.

## Alternatives écartées

- **Paquet npm `lucide` ou une gem d'icônes** : une dépendance de plus pour une vingtaine de fichiers SVG, et du
  JavaScript au chargement pour des icônes statiques.
- **Police d'icônes** : rendu moins net, accessibilité moins bonne, tout le jeu téléchargé.
- **Garder les emojis** : rendu différent selon le téléphone, couleur non maîtrisée, effet « IA » relevé par la revue.

## Conséquences

- Un thème sombre se fera en redéfinissant les jetons (la coque est en thème clair fixe d'ici là).
- Mettre à jour Lucide se fait à la main (recopier les fichiers utilisés), ce qui est rare et sans risque.