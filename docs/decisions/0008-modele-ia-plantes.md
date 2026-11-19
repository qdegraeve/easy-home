# 0008. Modèle d'IA pour les plantes : forfait Claude via `claude -p`, puis API si besoin

- Statut : acceptée
- Date : 2026-11-19

## Contexte

Le module plantes a besoin d'un modèle de vision pour deux choses : proposer l'espèce depuis une photo, et analyser l'état
d'une plante (observations, gravité, actions). Volume attendu : une dizaine de plantes, quelques analyses par semaine.
Contrainte : coût nul ou minimal.

## Décision

- Pendant le développement et tant que l'usage reste personnel, on utilise le **forfait Claude** du développeur via
  Claude Code en mode non interactif (`claude -p`), en lui passant le chemin de la photo et un prompt qui exige une
  réponse JSON.
- L'appel passe par un **adaptateur** (`Plants::Analyzer`) avec une interface unique. Le reste de l'app ne connaît pas le
  fournisseur. La réponse JSON est validée côté Rails avant d'être enregistrée.
- L'analyse tourne dans un **job** Solid Queue ; la page se met à jour en Turbo Stream à l'arrivée du résultat.
- En test, un **faux adaptateur** renvoie une réponse fixe : aucun appel réel.

## Alternatives écartées

- **API Claude dès maintenant** (Haiku : environ 0,05 centime par analyse) : la plus propre et quasi gratuite à ce
  volume. Gardée comme cible si le forfait ne convient plus.
- **Modèle local** (vision via Ollama) : gratuit, mais nettement moins bon pour diagnostiquer, et lent sans GPU.
- **Pl@ntNet** : bon pour identifier l'espèce, mais ne fait pas de diagnostic. Un second fournisseur pour un seul usage.
- **Clé API fournie par l'utilisateur** (« bring your own key », idée initiale) : inutile pour un usage privé.

## Conséquences

- Le serveur qui exécute les jobs doit avoir le CLI `claude` installé et authentifié. En local, c'est la session du
  développeur. Sur le serveur de la maison : CLI dans l'image et jeton longue durée (`claude setup-token`), traité au
  moment du déploiement.
- Le quota du forfait est partagé avec le développement : une analyse peut échouer ou attendre. L'app doit afficher
  l'échec et permettre de relancer.
- Le forfait vise un usage personnel. On passe à l'API Claude (nouvel adaptateur, nouvel ADR) si le quota gêne, si
  d'autres personnes utilisent l'app, ou si les conditions d'usage l'exigent.