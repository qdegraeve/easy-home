# 0017. Rappels à heure fixe

- Statut : acceptée
- Date : 2026-11-23

## Contexte

Jusqu'ici, la seule notification est le résumé du matin (ADR 0012), à l'heure choisie par chacun. La poubelle se sort
la veille de la collecte, le soir : un résumé du matin ne suffit pas, et une tâche « à ne pas rater » doit être
relancée tant qu'elle n'est pas faite (promesse de départ du produit).

## Décision

- **Un rappel facultatif par tâche** : `tasks.reminder_minute` (minutes après minuit, de 5 h à 22 h au quart d'heure,
  contrainte `CHECK` en base), **le jour de l'échéance**. Désactivé par défaut. Pas de décalage en jours : l'échéance
  d'une poubelle est le jour où on la sort. L'heure est celle du fuseau de l'application, sans heure d'été
  (Indian/Reunion), comme toutes les échéances (`due_at` = début du jour local) ; un foyer dans un autre fuseau
  demandera de calculer avec `households.time_zone`.
- Les compteurs ne valent que pour le jour de l'échéance (envois depuis son début) : une échéance déplacée repart de
  zéro. Changer l'heure du rappel en fait un nouveau rappel, envoyé à la nouvelle heure. Une tâche créée ou déplacée
  au jour même après son heure reçoit son rappel au passage suivant. Un rappel de 22 h part au passage de 22 h ; les
  relances ne sont jamais planifiées après 22 h.
- **Relances** pour les seules tâches « à ne pas rater » : au plus 3 notifications, au moins une heure d'écart, rien
  après 22 h ; chaque relance remplace la précédente sur le téléphone (`thread_id` par tâche). Une tâche souple n'a
  qu'une notification. « Fait » ou « Reporter » arrêtent les relances ; une échéance reportée est rappelée le
  lendemain à la même heure ; une échéance rouverte après un oubli n'est plus rappelée.
- **Destinataires** : les membres non invités qui suivent le foyer (`HouseholdMember#digest`), même si leur résumé du
  matin est désactivé : le rappel a été posé exprès sur la tâche. Le réglage devient « Foyers suivis : résumé du matin
  et rappels ».
- **Mécanisme** : un job récurrent toutes les 5 minutes (`SendRemindersJob`, Solid Queue, comme le résumé) appelle
  `Notifications::SendReminders`. `RemindersDueQuery` sélectionne les échéances dont le rappel (ou la relance
  suivante) est dû ; chaque envoi est **réservé de façon atomique** : la mise à jour du compteur reprend les conditions
  de la requête et la valeur lue, donc jamais deux envois, ni d'envoi pour une tâche déplacée, faite ou arrêtée entre
  la lecture et l'envoi. Réservé avant l'envoi : une seule tentative par envoi, comme le résumé du matin. Compteurs sur
  l'échéance : `reminders_sent`, `last_reminded_at`. Après une panne, le rappel en retard part au retour, puis au
  moins une heure d'écart : jamais de rafale.
- **Contenu** : « Sortir la poubelle jaune », ou « Nettoyer le filtre · Lave-vaisselle » ; relance « Toujours à faire :
  … ». Jamais le « Comment faire ». La notification ouvre la feuille de la tâche (`path`), une fois l'app Android
  capable de recevoir les notifications.
- Le résumé du matin cite une tâche du jour dont le rappel est encore à venir avec son heure : « Ce soir 19 h :
  sortir la poubelle jaune » ; la ligne d'« Aujourd'hui » d'une tâche de la maison du jour aussi (« ce soir 19 h »).
  Une tâche en retard n'est plus rappelée, son heure n'est pas annoncée.

## Alternatives écartées

- **Un job planifié par échéance** (`set(wait_until:)`) : à replanifier dans chaque service qui déplace une échéance
  (faire, reporter, annuler, recalculer, modifier, manquer), et Solid Queue n'annule pas proprement un job planifié.
- **Une colonne `remind_at` sur l'échéance** : donnée dérivée à tenir à jour aux mêmes endroits.
- **Un rappel avec décalage en jours** (« la veille ») : aucun cas réel une fois l'échéance posée au jour du geste.

## Conséquences

- Un passage toutes les 5 minutes : un rappel part au plus 5 minutes après son heure.
- Tant que l'app Android ne reçoit pas les notifications (Firebase à venir), les rappels sont prêts côté serveur mais
  ne s'affichent pas sur le téléphone.