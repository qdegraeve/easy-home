# 0011. Stockage des photos : Active Storage sur disque, images normalisées sans métadonnées

- Statut : acceptée
- Date : 2026-11-20

## Contexte

Le suivi des plantes passe par des photos prises au téléphone. Une photo de téléphone pèse plusieurs Mo et porte des
métadonnées EXIF, dont souvent la position GPS : elle révèle l'adresse de la maison. Les photos serviront aussi à
l'analyse par l'IA (ADR 0008), qui ne doit recevoir ni l'adresse ni les métadonnées.

## Décision

- **Active Storage**, service disque (`storage/`), sur le volume Kamal `easy_home_storage` en production.
- **Contrôle du fichier sur son contenu** (`PhotoUpload`, détection par Marcel) : JPEG, PNG ou WebP, 15 Mo maximum.
  Le nom ou le type annoncé par le navigateur ne comptent pas. Les dimensions sont lues dans l'en-tête avant tout
  traitement : au-delà de 100 mégapixels (bombe de décompression), le fichier est refusé. Le chargement est strict :
  une image aux données corrompues ou tronquées est refusée au lieu d'être enregistrée abîmée.
- **Normalisation à l'envoi** (`Photos::Add`, libvips via `image_processing`) : rotation selon l'orientation du
  téléphone, 2048 px maximum, réenregistrement en JPEG qualité 85 **sans aucune métadonnée**. Seule cette version est
  stockée : l'original n'est pas conservé.
- **Variantes** pour l'affichage : vignette carrée 320 px et grand format 1600 px.
- **Accès** : liens signés standard d'Active Storage, impossibles à deviner mais accessibles sans connexion à qui
  possède le lien. Acceptable parce que les photos ne portent plus de métadonnées.

## Alternatives écartées

- **Conserver l'original** : plus de place et le GPS stocké ; aucune utilité identifiée.
- **Contrôleur de fichiers authentifié** : plus strict, mais plus de code pour un risque faible (lien partagé par
  erreur, photo sans métadonnées). À reconsidérer si des photos sensibles apparaissent.
- **Gem de validation** (`active_storage_validations`) : une dépendance pour deux règles simples.

## Conséquences

- Une photo stockée pèse quelques centaines de Ko au plus.
- libvips est nécessaire partout où l'app tourne (déjà dans l'image Docker et la CI).
- Une photo illisible malgré un type valide est refusée avec le même message qu'un fichier qui n'est pas une image.
