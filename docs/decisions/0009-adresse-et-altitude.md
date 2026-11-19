# 0009. Adresse de la maison : géocodage IGN et altitude Open-Meteo

- Statut : acceptée
- Date : 2026-11-19

## Contexte

Les conseils d'arrosage et les diagnostics dépendent du climat local, qui varie beaucoup à La Réunion, y compris dans
une même commune (littoral, mi-pentes, Hauts). Demander la commune et l'altitude est imprécis et pénible pour
l'utilisateur. On veut qu'il saisisse seulement son adresse.

## Décision

- **Autocomplétion et géocodage** de l'adresse par le service de géocodage de l'IGN (Géoplateforme,
  `data.geopf.fr/geocodage`), successeur de l'API Adresse de data.gouv.fr. Gratuit, sans clé, couvre La Réunion.
- **Altitude** calculée depuis la position avec l'API d'élévation d'Open-Meteo (gratuite en usage non commercial, sans
  clé). Open-Meteo servira aussi plus tard pour la météo (arrosage ajusté par la pluie).
- Appels HTTP simples depuis Rails, sans nouvelle gem, derrière deux adaptateurs (`Geo::Geocoder`, `Geo::Elevation`).
  En test, de faux adaptateurs : aucun appel réseau.
- On stocke l'adresse choisie, la latitude, la longitude et l'altitude. L'utilisateur voit l'altitude calculée et peut
  la corriger.
- **Confidentialité** : l'adresse reste en base. L'IA reçoit seulement une position arrondie (environ 1 km) et
  l'altitude. Aucune adresse réelle dans le dépôt (seeds et specs fictifs).

## Alternatives écartées

- **Commune et altitude saisies à la main** : imprécis (une commune comme Saint-Paul va du littoral aux Hauts) et plus
  d'effort pour l'utilisateur.
- **Position GPS du téléphone** : précise, mais oblige à configurer la maison depuis chez soi, et ne marche pas sur
  desktop. Pourra s'ajouter en option (« utiliser ma position »).
- **Altimétrie de l'IGN** : plus précise, mais Open-Meteo suffit à la précision utile et fournira aussi la météo.
- **Gem de géocodage** (`geocoder`) : une dépendance pour deux appels HTTP.

## Conséquences

- Deux services externes : en cas d'indisponibilité, l'adresse peut être enregistrée sans altitude, qui sera calculée
  plus tard ou saisie à la main.
- Le free tier d'Open-Meteo est réservé au non commercial : à revoir si l'app devenait un produit.