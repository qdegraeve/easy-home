# 0001. Monolithe Rails + Hotwire Native pour le mobile

- Statut : acceptée
- Date : 2026-09-28

## Contexte

Side project à usage privé, avec deux objectifs : résoudre un vrai besoin (rappels domestiques) et explorer des technos. Le développeur est expert Rails et débute en mobile. Il doit par ailleurs intervenir sur une app en webview et veut mesurer ce que permet Hotwire Native et sa complexité de déploiement.

## Décision

Un monolithe Rails 8 (Hotwire) sert à la fois le web et une app Android Hotwire Native, construite d'abord pour Android uniquement.

## Alternatives écartées

- **Expo / React Native + Supabase + synchronisation local-first** : rappels planifiés sur l'appareil, plus robustes hors ligne, et iOS quasi gratuit. Mais beaucoup de nouveautés à la fois (TypeScript, React, synchronisation) et moins proche de l'objectif webview.
- **Kotlin natif + PocketBase** : meilleure intégration Android, mais aucune réutilisation des compétences Rails.
- **Phoenix (Elixir)** : philosophie proche de Rails, mais apprentissage d'un nouveau langage côté serveur sans bénéfice pour l'objectif mobile.

## Conséquences

- Les rappels dépendent du serveur et du réseau : fiabilité à soigner (Firebase en priorité haute, relances). Piste possible plus tard : planifier aussi localement les notifications des semaines à venir.
- Une seule base de code métier, testée avec les outils maîtrisés.
- Nécessite un hébergement HTTPS public.
