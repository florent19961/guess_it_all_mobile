---
story: 2-3-ensembles-stockage-editeur
epic: epic-2-mode-fiesta
status: superseded
tier: "R ③ schéma persisté (nouvelle clé) + L écrans"
collisions: ["nouvelle clé guessItAll_fiestaEnsembles", "lib/app.dart + constants.dart (routes, conflit textuel avec 2-4)"]
depends: [2-2-fondation-modele-fiesta]
model: Opus
lane: B (parallèle de la lane A, ne touche ni game_provider.dart ni game_state.dart)
---

> ⚠️ **Remplacé par `feat/ensembles-perso` (2026-11-04)** — parcours et contrat décrits dans
> `lib/screens/CLAUDE.md`. Le stockage (`guessItAll_fiestaEnsembles`) décrit ici reste valable ;
> les écrans (liste « Mes ensembles » + éditeur poussé, après les équipes) ne le sont plus.

# 2-3 : Ensembles (clé versionnée, validation, liste et éditeur)

## User story

En tant qu'hôte de soirée, je veux enregistrer mes réglages Fiesta sous un nom (« Soirée chez
Max ») et les réutiliser, les modifier, les dupliquer ou les supprimer. Ainsi, je ne refais pas
tous les curseurs à chaque partie.

## Périmètre

- **Service** `lib/services/fiesta_ensemble_service.dart` (singleton), sur le modèle exact de
  `GameHistoryService` (`lib/services/game_history_service.dart:15-110`) : clé
  **`guessItAll_fiestaEnsembles`**, écriture via `wrapWithSchema`, lecture via `unwrapSchema` et
  quarantaine. Charge utile : `{ensembles: [...], lastUsedId: String?}`. Chaque ensemble a un
  `id` stable (uuid, déjà en dépendance via `word_event.dart:1`), un `name` et des `FiestaRules`
  (type de la story 2-2).
- **Validation pure** `validateEnsemble(ensemble) → List<String>` (messages FR), dans
  `lib/models/fiesta/`. Elle bloque l'enregistrement si :
  - le nom est vide après `trim` ;
  - un modificateur actif est réglé sur « tiré pour tous » alors que le tirage symétrique est
    coupé ou à 0 ;
  - un modificateur actif est réglé sur « proposé à l'équipe menée » alors que le 1 parmi 3 est
    coupé ;
  - un modificateur « manche 3 seulement » est fixé sur une autre manche, ou démarre avant M3 ;
  - deux modificateurs incompatibles (table de 2-2) sont **fixés sur la même manche** ;
  - un modificateur « proposé » démarre en manche 1 (le choix a lieu entre deux manches : M2 au
    plus tôt, maquette `edit`).
- **Écrans** (maquette `perso` et `edit`) :
  - liste « Mes ensembles » : compteur `n / 10`, Créer, et pour chaque ensemble Utiliser /
    Modifier / Dupliquer / Supprimer (avec confirmation via `AppModal`,
    `lib/widgets/common/app_modal.dart`). À 10, Créer et Dupliquer sont désactivés avec le
    message de la maquette ;
  - éditeur : nom (obligatoire, 30 caractères max), catalogue (interrupteur, arrivée, manche,
    charges), 1 parmi 3, rattrapage (5 curseurs), tirage symétrique (0 à 2), règles communes.
    Les erreurs de `validateEnsemble` s'affichent sous le bouton, qui reste grisé tant qu'il y en
    a.
  - **Utiliser** renvoie l'ensemble choisi à l'appelant (story 2-4) et met à jour `lastUsedId`.
    Tant que 2-4 n'est pas mergée, la liste est atteignable par une route seulement.
- Nouvel ensemble = valeurs par défaut de la maquette (`mkSet`).

## Critères d'acceptation

1. **Étant donné** aucune clé, **quand** on ouvre la liste, **alors** elle est vide avec
   « Aucun ensemble. Crée le premier ! ».
2. **Étant donné** 10 ensembles, **quand** on tente d'en créer ou d'en dupliquer un, **alors**
   c'est impossible : le service refuse aussi (la borne n'est pas seulement visuelle).
3. **Étant donné** un éditeur avec un nom vide, ou une configuration impossible (liste
   ci-dessus), **quand** on regarde le bouton, **alors** il est grisé et l'explication est
   visible. Rien n'est écrit.
4. **Étant donné** Modifier, **quand** on enregistre, **alors** l'ensemble est remplacé **sur
   place** (même `id`, même position). Une partie déjà lancée avec cet ensemble n'est pas
   affectée (gel de 2-2).
5. **Étant donné** Dupliquer, **alors** une copie nommée « <nom> (copie) », tronquée à 30
   caractères, apparaît (Q13 : pas d'unicité imposée).
6. **Étant donné** Supprimer, **alors** une confirmation est demandée. Si l'ensemble supprimé
   était `lastUsedId`, ce champ est effacé.
7. **Étant donné** un blob illisible ou venu d'une version future, **quand** on lit, **alors** il
   est mis en quarantaine et la liste repart vide, sans crash. **Étant donné** un ensemble
   illisible parmi d'autres, **alors** seul celui-ci est ignoré. **Étant donné** un modificateur
   d'id inconnu dans un ensemble lisible, **alors** ce modificateur est ignoré, pas l'ensemble.
8. `kCurrentSchemaVersion` reste à `1` : c'est une **nouvelle** clé, donc rien à migrer
   aujourd'hui. Le blob porte quand même l'enveloppe versionnée dès la première écriture.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- Modèle à copier : `lib/services/game_history_service.dart:20` (clé), `:43-78` (lecture,
  quarantaine, tolérance par entrée), `:89-100` (écriture enveloppée).
- `lib/services/persisted_schema.dart:82-113` : `wrapWithSchema` / `unwrapSchema`, sans
  modification.
- `lib/utils/constants.dart:26-29` : les autres clés `guessItAll_*`. On y ajoute la nouvelle si on
  veut la regrouper, ou on la laisse en `static const` du service comme `GameHistoryService`.
- Routage : `lib/app.dart:56-92` (`_buildCurrentScreen`) et `lib/utils/constants.dart:33-47`.
  **Conseil** : ouvrir l'éditeur par `Navigator.push` depuis la liste, plutôt que via
  `currentScreen`. Cela évite de faire passer le contexte d'édition par `GameProvider`.
- `lib/services/storage_service.dart` : **non touché**.

## Pièges

- Ne **pas** ranger les ensembles dans `guessItAll_settings` : la décision veut une clé à part,
  et `GameSettings` ne change pas.
- `prefs.remove` sur la quarantaine supprime **tous** les ensembles de l'utilisateur : ne mettre
  en quarantaine qu'un blob structurellement illisible, jamais à cause d'**un** ensemble
  (critère 7).
- Le `catch` générique de `GameHistoryService.load` (`:72-76`) rend vide **sans** effacer. Le
  garder : sinon un `record` suivant écraserait tout (piège déjà vécu, `game_result.dart:129-134`).
- Les écritures sont asynchrones et non sérialisées : deux taps rapides sur Dupliquer peuvent
  dépasser 10. Garder la borne dans le service, sur la liste relue.

## Tests (règle minimale)

- `test/services/fiesta_ensemble_service_test.dart` : critère 7 (blob corrompu → quarantaine,
  entrée illisible → ignorée seule, id inconnu → modificateur ignoré), critère 2 (borne 10 dans
  le service), aller-retour avec enveloppe (critère 8). Modèle :
  `test/services/game_history_test.dart` et `test/helpers/test_prefs.dart`.
- `test/models/fiesta/ensemble_validation_test.dart` : un cas par règle bloquante, plus un
  ensemble valide (le cas nominal, pour distinguer « refusé » de « garde neutralisée »).
- Pas de widget test pour la liste ni pour l'éditeur.

## Recette device (Florent, Android + iOS)

1. Créer 2 ensembles, en modifier un, en dupliquer un, en supprimer un (confirmation visible).
2. Tuer l'app, rouvrir : la liste est intacte.
3. Monter à 10 : Créer et Dupliquer sont grisés avec le message.
4. Éditeur : vider le nom, mettre le tirage à 0 avec un modificateur « tiré pour tous » : le
   bouton est grisé et le message s'affiche. Vérifier le clavier et la zone sûre (encoche iOS,
   barre de gestes Android).
5. Rattrapage (revue r2, MINOR 3) : l'interrupteur se lit « un curseur > 0 ». Juger si c'est
   gênant : seul le plafond > 0 affiche « on » sans effet réel ; ramener le dernier curseur
   non nul à 0 bascule l'interrupteur sur off et masque les curseurs pendant le glissement.
6. Couper le tirage sur l'ensemble par défaut affiche un message par modificateur tiré (r1,
   MINOR 7) : lisible ou à regrouper ?

## Notes d'implémentation (lane B, 2026-11-03)

- Ancien contrat (remplacé, voir le bandeau en tête), pour mémoire :
- **Point d'entrée pour 2-4** : `FiestaEnsemblesScreen(onBack: …, onUse: (FiestaEnsemble e) …)`
  (`lib/screens/fiesta_ensembles_screen.dart`). `onUse` reçoit l'ensemble déjà marqué
  `lastUsedId` ; `e.rules` (mode `custom`, `ensembleName` = nom) se passe tel quel à
  `startGame(fiesta: …)`. En attendant 2-4, la route `AppConstants.screenFiestaEnsembles` existe
  dans `app.dart` (aucun bouton n'y mène) et les deux callbacks renvoient à l'accueil.
  Contrat détaillé : `lib/screens/CLAUDE.md`.
- **Recette device** : faute de bouton avant 2-4, elle se joue après 2-4 (ou en appelant la
  route à la main).
- **Interprétations** : rattrapage avec un interrupteur d'interface (off = 5 curseurs à 0, on =
  valeurs Auto ; rien de plus persisté) ; le tirage
  pour tous d'un ensemble est actif si `symmetric` **et** `drawCount > 0` ; les modificateurs
  « manche 3 seulement » ont leur manche verrouillée à 3 dans l'éditeur (comme la maquette) ;
  un nouvel ensemble part du `mkSet` de la maquette (`defaultEnsembleRules`).
