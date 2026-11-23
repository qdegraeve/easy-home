# 0017. Rappels à heure fixe

- Statut : acceptée
- Date : 2026-11-23

## Contexte

Jusqu'ici, la seule notification est le résumé du matin (ADR 0012), à l'heure choisie par chacun. La poubelle se sort
la veille de la collecte, le soir : un résumé du matin ne suffit pas, et une tâche « à ne pas rater » doit être
relancée tant qu'elle n'est pas faite (promesse de départ du produit).

## Décision

- **Un rappel facultatif par tâche** : `tasks.reminder_minute` (minutes après minuit, dans le fuseau du foyer, de
  5 h à 22 h au quart d'heure, contrainte `CHECK` en base), **le jour de l'échéance**. Désactivé par défaut. Pas de
  décalage en jours : l'échéance d'une poubelle est le jour où on la sort.
- **Relances** pour les seules tâches « à ne pas rater » : au plus 3 notifications, au moins une heure d'écart, rien
  après 22 h ; chaque relance remplace la précédente sur le téléphone (`thread_id` par tâche). Une tâche souple n'a
  qu'une notification. « Fait » ou « Reporter » arrêtent les relances ; une échéance reportée est rappelée le
  lendemain à la même heure ; une échéance rouverte après un oubli n'est plus rappelée.
- **Destinataires** : les membres non invités qui suivent le foyer (`HouseholdMember#digest`), même si leur résumé du
  matin est désactivé : le rappel a été posé exprès sur la tâche. Le réglage devient « Foyers suivis : résumé du matin
  et rappels ».
- **Mécanisme** : un job récurrent toutes les 5 minutes (`SendRemindersJob`, Solid Queue, comme le résumé) appelle
  `Notifications::SendReminders`. `RemindersDueQuery` sélectionne les échéances dont le rappel (ou la relance
  suivante) est dû ; chaque envoi est **réservé de façon atomique** (`UPDATE … SET reminders_sent = reminders_sent + 1
  WHERE reminders_sent = <valeur lue>`), donc jamais deux fois, même si deux passages se chevauchent. Compteurs sur
  l'échéance : `reminders_sent`, `last_reminded_at`. Après une panne, le rappel en retard part au retour, puis au
  moins une heure d'écart : jamais de rafale.
- **Contenu** : « Sortir la poubelle jaune », ou « Nettoyer le filtre · Lave-vaisselle » ; relance « Toujours à faire :
  … ». Jamais le « Comment faire ». La notification ouvre la feuille de la tâche (`path`), une fois l'app Android
  capable de recevoir les notifications.
- Le résumé du matin cite une tâche avec rappel avec son heure : « Ce soir 19 h : sortir la poubelle jaune ».

## Alternatives écartées

- **Un job planifié par échéance** (`set(wait_until:)`) : à replanifier dans chaque service qui déplace une échéance
  (faire, reporter, annuler, recalculer, modifier, manquer), et Solid Queue n'annule pas proprement un job planifié.
- **Une colonne `remind_at` sur l'échéance** : donnée dérivée à tenir à jour aux mêmes endroits.
- **Un rappel avec décalage en jours** (« la veille ») : aucun cas réel une fois l'échéance posée au jour du geste.

## Conséquences

- Un passage toutes les 5 minutes : un rappel part au plus 5 minutes après son heure.
- Tant que l'app Android ne reçoit pas les notifications (Firebase à venir), les rappels sont prêts côté serveur mais
  ne s'affichent pas sur le téléphone.