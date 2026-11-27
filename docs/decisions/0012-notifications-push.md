# 0012. Notifications push : résumé du matin par action_push_native et Firebase

- Statut : acceptée
- Date : 2026-11-20

## Contexte

Le point de départ du projet est de ne plus oublier une tâche (la poubelle jaune, l'arrosage). L'app Android
(Hotwire Native) doit donc recevoir des notifications. La plupart des échéances sont des jours sans heure : une
notification « à l'échéance » partirait à minuit. Chaque membre doit pouvoir régler ce qu'il reçoit.

## Décision

- **Un résumé le matin**, une seule notification par utilisateur et par jour, qui liste les tâches dues aujourd'hui
  et en retard, groupées comme l'écran (revue UX #21) : les tâches « à ne pas rater » en tête, tous les arrosages en un
  élément, puis le reste (« 3 tâches aujourd'hui » : « Arroser 2 plantes, Pailler le pied (Citronnier) »). Rien n'est
  envoyé les jours sans tâche. Toucher la notification ouvre l'accueil.
- **Réglages par utilisateur** (page « Notifications ») : résumé activé ou non, heure (au quart d'heure, de 5 h à
  22 h, 8 h par défaut, fuseau de l'app), « seulement ce qui ne doit pas être raté » (`digest_scope` `all` /
  `critical`, revue UX #22 : un jour sans tâche « à ne pas rater », rien n'est envoyé et la journée est consommée),
  foyers inclus parmi ceux qu'il gère (pas ceux où il est invité).
- **Gem `action_push_native`** (37signals, `~> 0.3`) : elle envoie à Firebase Cloud Messaging (et à Apple si un jour
  une app iOS existe), passe par Active Job (donc Solid Queue), gère les relances et supprime les appareils dont le jeton
  est invalide. La classe `ApplicationPushNotification` est la frontière avec le fournisseur ; la gem désactive l'envoi
  en test, et les specs vérifient les jobs mis en file. Pas d'adaptateur maison en plus : il ne ferait que recopier
  cette frontière.
- **Un appareil appartient à une session** (`Session`, propriétaire polymorphe de `ApplicationPushDevice`), pas
  directement à l'utilisateur : se déconnecter sur le téléphone supprime la session et l'appareil, donc un téléphone
  déconnecté ne reçoit plus rien. Un jeton est unique : un téléphone reconnecté par quelqu'un d'autre change de
  propriétaire. Contrepartie acceptée : qui connaît le jeton Firebase d'un téléphone (accès au téléphone) peut le
  rattacher à son compte ; il ne lit rien, mais ce téléphone reçoit ses notifications à la place de celles de son
  propriétaire.
- **Envoi** : `SendDigestsJob`, récurrent toutes les 5 minutes (`config/recurring.yml`), appelle
  `Notifications::SendDigests`, qui retient les utilisateurs dont l'heure est passée, sans résumé ce jour-là et avec au
  moins un téléphone. `Notifications::SendDigest` réserve le jour de façon atomique (`last_digest_on`) avant d'envoyer :
  jamais deux résumés le même jour, même si deux passages se chevauchent.
- **Retard maximal de 2 heures** : après une panne ou un déploiement, un résumé en retard part encore jusqu'à 2 heures
  après son heure, pas au-delà. Un résumé du matin n'arrive jamais le soir (premier téléphone enregistré à 21 h, résumé
  activé l'après-midi) : le suivant part le lendemain.
- **Enregistrement du téléphone** : `POST /push_devices` avec le jeton Firebase, envoyé par la page dans la session
  de l'utilisateur connecté (bridge component `push`). La **permission** (Android 13+) n'est demandée que sur un geste
  de l'utilisateur, le bouton « Recevoir les notifications sur ce téléphone » de la page Notifications, jamais au
  premier lancement ; refusée, la page l'explique et ouvre les réglages Android de l'app. Ensuite, chaque page de
  l'app redonne le jeton, et la page ne le poste que si la session ne le connaît pas (empreintes SHA-256 des jetons
  de la session dans la page) : une nouvelle session après une reconnexion, un jeton renouvelé par Firebase.
- **Réception** : Firebase affiche lui-même la notification quand l'app est en arrière-plan (canal « Rappels »,
  icône dédiée) ; au premier plan, l'app l'affiche. La toucher ouvre `data.path` dans l'onglet Aujourd'hui (un
  chemin de l'app seulement, jamais un autre site).
- **Secrets** : le compte de service Firebase (`action_push_native.fcm.encryption_key`, le fichier JSON entier, et
  `project_id`) dans les credentials Rails, jamais dans le dépôt. `android/app/google-services.json` n'est pas versionné
  (dépôt public) : sans lui, l'app se construit sans Firebase (CI) et dit qu'elle ne peut pas recevoir de notifications.

## Alternatives écartées

- **Une notification par échéance, au moment de l'échéance** : minuit pour la plupart des tâches, et du bruit quand
  plusieurs tâches tombent le même jour.
- **`noticed`** : notifications multi-canaux avec historique en base. Plus de structure que nécessaire pour un seul
  canal et un seul message.
- **Appel direct à l'API HTTP de Firebase** : authentification OAuth du compte de service, relances et jetons morts à
  réécrire, déjà faits par la gem.

## Conséquences

- Les tâches ajoutées dans la journée, après le résumé, ne sont pas notifiées ce jour-là.
- Une seule heure par utilisateur, pour tous ses foyers.
- Les notifications ne partent qu'en production (tâche récurrente) ; en développement, on les déclenche à la main
  (bouton « M'envoyer une notification de test » ou `Notifications::SendDigests.new.call` en console).
- Reste à faire : l'action « Fait » depuis la notification, qui demandera un jeton d'API par appareil.
