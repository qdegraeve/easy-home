# 0015. La pluie compte comme un arrosage

- Statut : acceptée
- Date : 2026-11-22

## Contexte

La pluie arrose les plantes dehors. Une tâche « arroser » le lendemain d'une grosse pluie est du bruit, et c'est
exactement ce qui fait décrocher d'une app de rappels (revue UX, section « Arrosage et météo »). La maison a déjà sa
position (ADR 0009), et Open-Meteo y était annoncé pour la météo.

## Décision

- **Où il pleut** : une case « Reçoit la pluie » sur chaque emplacement (`locations.rain_exposed`), **décochée par
  défaut**, y compris pour les emplacements existants. La case « Abrité du vent » ne suffit pas : une terrasse couverte
  peut être exposée au vent sans jamais être mouillée. Les plantes sans emplacement ne sont jamais touchées.
- **Quand** : un job chaque soir à 22 h, heure de La Réunion (`RecordRainJob`, `config/recurring.yml`), avant le
  résumé du matin.
- **Données** : le cumul de pluie de la journée à la position de la maison, par l'API de prévision d'Open-Meteo
  (`daily=precipitation_sum`, fuseau du foyer : mesuré pour les heures passées, prévu pour les deux dernières). Gratuit,
  sans clé. Appel derrière l'adaptateur `Weather::OpenMeteoRain` (`Weather.rain`), remplacé par un faux en test.
- **Une fois par jour et par foyer** : le cumul est stocké (`rainfalls.fell_on`, une ligne par foyer et par jour,
  index unique). Il n'est demandé qu'une fois. La règle est appliquée jusqu'à ce qu'elle soit passée
  (`rainfalls.applied_at`) : un redémarrage au milieu est rattrapé au passage suivant, sans toucher deux fois une
  tâche déjà fermée par la pluie ce jour-là. Si le service ne répond pas, rien n'est enregistré ni changé. Un foyer en
  erreur n'empêche pas les autres (erreur signalée par `Rails.error`).
- **Règle** (`Rain.effect`, domaine pur) : appliquée aux arrosages ouverts dus au plus tard le lendemain, des plantes
  actives d'un emplacement qui reçoit la pluie.
  - **10 mm ou plus** : l'arrosage est noté fait par la pluie (`task_occurrences.source = "rain"`, sans auteur) ; le
    suivant repart de ce jour (récurrence glissante).
  - **De 3 à 10 mm** : l'arrosage est décalé d'un jour, sans être noté fait (trace « décalé » comme le bouton
    « Demain » ; un arrosage dû le lendemain passe au surlendemain).
  - **Moins de 3 mm** : rien.
  - Un arrosage déjà fait dans la journée reste tel quel, quelle que soit la pluie. Seuils à affiner à l'usage.
- **Mêmes services** : la pluie passe par `Tasks::Complete` et `Tasks::Postpone` (paramètre `source:`), sous le même
  verrou que les gestes de l'utilisateur. Une validation par la pluie s'annule depuis le journal ou l'historique comme
  une validation manuelle.
- **Affichage** : sur « Aujourd'hui », une ligne le lendemain (« Pluie hier (14 mm) : 2 plantes arrosées. ») ; dans le
  journal, « par la pluie » à la place de l'auteur ; dans l'historique de la plante, « Arrosée par la pluie ».

## Alternatives écartées

- **Réutiliser « Abrité du vent »** : faux pour une terrasse couverte ou une véranda ouverte.
- **Case cochée par défaut** : la météo aurait agi dès la mise en production sur des emplacements jamais vérifiés
  (intérieur, sous un toit).
- **Rappeler l'API à chaque affichage** : inutile ; le cumul du jour stocké sert aussi à l'historique.
- **Tenir compte des prévisions** (ne pas arroser s'il pleut demain) : plus tard, avec la taille du pot et le besoin
  en eau de l'espèce.

## Conséquences

- Nouvelle table `rainfalls` ; colonnes `locations.rain_exposed` et `task_occurrences.source` (`manual` / `rain`).
- Rien ne change pour un foyer tant qu'aucun emplacement n'est marqué « Reçoit la pluie ».
- Le fuseau utilisé pour « aujourd'hui » reste celui de l'application (`Indian/Reunion`), comme le reste des tâches.
- Limites connues : un décalage par la pluie ne s'annule pas depuis le journal (comme le bouton « Demain » une fois
  le toast passé) ; modifier la tâche le lendemain peut ramener l'échéance au lendemain du décalage (recalcul) ; un
  job retardé au-delà de minuit prendrait la pluie du jour suivant.
