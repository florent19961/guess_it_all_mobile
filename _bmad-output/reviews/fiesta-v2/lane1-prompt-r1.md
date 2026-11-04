# Revue Fiesta v2 — lane 1 (modèle, ensembles, éditeur) — round 1

**Tier : RISQUÉ** (machine à états de la partie, persistance `SharedPreferences`). Lecture seule.
Lis le patch `_bmad-output/reviews/fiesta-v2/lane1-patch-r1.diff` (calculé sur la merge-base avec
`origin/main`), jamais `git diff` toi-même ; lis le code du worktree
`/home/florent19961/guess-it-all-fiesta-v2` (branche `feat/fiesta-v2-modele`) pour le contexte.
Écris ton rapport dans `_bmad-output/reviews/fiesta-v2/lane1-review-r1.md`.

## Objectif

Spec Fiesta v2 (décisions Florent 2026-11-04) §1, §2, §4, §5 :

- Nouveau `ModifierSetting` `{active, rounds ⊂ {1,2,3}, mode, charges, perGame}`, mode exclusif
  `always` / `draw` (« Toute la manche, pour tous ») ou `stock` / `offer` (« Cartouche · un tour »).
- `FiestaRules` v2 `{format: 2, mode, autoCalibrate, ensembleName?, modifiers, drawCount 0-5,
  pick3Choices 1-3, catchUp}` ; supprimés : `symmetric`, `oneOfThree`, `oneAnswer`, `arrival`,
  `startRound`, `fixedRound`, plafond 2/3 (`maxModifiersPerTeam`, `canAdd(maxPerTurn)`, `_capped`).
- `one_answer` = malus normal du catalogue ; `sounds_only` ajouté (famille mime, M3) ; les deux
  **en fin** de `kModifierCatalog`. Exceptions cartouche : `block_guesser`, `double_points`.
- 7 ensembles fournis (`kProvidedEnsembles`, code, ids `provided_*`, jamais écrits, seulement
  duplicables), « Fiesta classique » présélectionné.
- Éditeur poussé (`FiestaEnsembleEditorScreen`) : Enregistrer toujours actif, erreurs précises
  après appui, noms uniques (casse/espaces), doublon de réglages refusé, brouillon en mémoire,
  popup « Tu veux l'enregistrer ? », retour Android.
- Moteur : `always` + `draw` (déterministe par gameId+manche, incompatibles sautés, sans plafond),
  `offer` en `pick3Choices` rangées de 3 cartes (même écran, une carte par rangée), Auto ré-exprimé
  (`autoRules`).
- Hors lane (lane 2) : écran « Ce tour / Réserve », malus en stock ciblés. **Résidu assumé** :
  malus `stock` persistés mais sans effet en jeu ; bonus `stock` = mécanisme de charges existant.

## Décisions prises par l'implémenteur (à challenger)

1. **Forme v1 illisible, pas traduite** (Fiesta jamais publiée) : marqueur `format: 2` dans
   `FiestaRules.toJson`. Ensemble v1 → ignoré (réécrit tel quel dans le blob) ; partie Fiesta
   suspendue v1 → abandonnée par `GameProvider._loadData` (accueil, joueurs gardés, état effacé) au
   lieu d'être relue en Classique. `kCurrentSchemaVersion` non bumpé.
2. Charges d'une instance : règles de manche → `def.defaultCharges` ; stock → N (ou N − dépensées
   avant pour « pour la partie », via `chargesUsed`) ; carte offer → 1 pour ×2 / Deux mots, sinon
   `defaultCharges`. Passe gratuite en stock = N passes gratuites par tour toute la manche (intérim).
3. Rangées d'offres : rangée 0 garde la graine figée `offerSeed(gameId, round, teamId)` ; rangée k
   = `offerSeed(gameId, round, '$teamId#k')` ; pas d'id repris d'une rangée à l'autre ; les rangées
   d'une équipe ne dépendent que des choix des équipes passées AVANT elle ; ses propres choix
   grisent (`canChooseOffer`, `isUsefulOffer`). Équipe finie = chaque rangée a sa carte ou n'a
   plus de carte utile. `OfferChoice.row` ajouté (absent = 0).
4. Doublon = `settingsKey` (réglages hors nom, modificateurs actifs seulement, cartouches
   seulement en stock).
5. « Explosif » et « L'injustice » n'activent qu'UN mime (`mime_no_arms`) : la règle « un seul mime
   à la fois » de l'éditeur prime sur « tous les malus ». À confirmer.
6. Rattrapage : l'éditeur n'a plus que l'interrupteur (maquette) — on = `CatchUpRules.auto`, off =
   tout à 0 ; les curseurs fins ont disparu de l'UI (valeurs d'un blob conservées).
7. Nouvel ensemble = `defaults()` de la maquette (Malus de 10 s, Mot à l'envers, Mime sans les bras,
   Passe gratuite, ×2 en stock ; Une seule réponse Toujours ; 1 tiré, 1 choix, rattrapage on).
8. Bug du nom : reproduit par test sur `origin/main` (l'éditeur en ligne repartait vierge après
   un enregistrement et affichait aussitôt « Donne un nom »). Racine corrigée : erreurs affichées
   seulement après un appui sur Enregistrer ; nom lu sur le contrôleur (listener).

## Questions précises

1. Tous les chemins de mutation de `FiestaState` (startGame, nextRound/`plan.apply`, chooseOffer,
   charges, retour arrière, app tuée) restent-ils cohérents avec les cartouches en stock
   (`stockForRound`) et les choix multi-rangées ? En particulier : `_doneChoosing` /
   `nextChooserId` peuvent-ils bloquer la transition (équipe jamais « finie ») ou la laisser
   passer avec une rangée encore choisissable ?
2. `stockForRound` « pour la partie » : le décompte par `chargesUsed` (round < N) est-il juste
   après un retour arrière qui rend une charge, et sur la continuation de fin de manche ?
3. L'abandon d'une partie v1 dans `_loadData` (`return` anticipé) saute-t-il quelque chose
   d'indispensable (analytics `resumeGame`, `notifyListeners`, session) ? Un snapshot
   `preValidationSnapshot` v1 peut-il ressurgir par un autre chemin ?
4. `FiestaEnsemble.tryFromJson` refuse un id `provided_*` : nécessaire ou sur-dimensionné ?
5. L'éditeur : la logique de retour (`_back`) — rien modifié / incomplet → brouillon / complet →
   popup — et le brouillon statique `FiestaEnsemblesScreen.draft` (création vs modification
   d'un ensemble) ont-ils un trou (brouillon perdu, brouillon resservi au mauvais ensemble,
   double pop) ? Parité Android/iOS du `PopScope`.
6. Tests : valeur et mutation testing sur les tests ajoutés/modifiés (voir liste ci-dessous) ; un
   test qui nomme une garantie l'exerce-t-il ? Redondances ?
7. Sur-dimensionnement : un mécanisme du diff dont la racine est un choix de spec plus simple ?

## Tests

Ajoutés ou réécrits : `test/models/fiesta/symmetric_draw_test.dart` (tirage sans plafond,
exceptions cartouche, Auto + one_answer, stock), `ensemble_validation_test.dart` (fournis valides
et distincts, nom vide/pris, doublon, sans manche, exclusivité des modes, « Toujours »
incompatibles), `offers_test.dart` (rangées), `test/services/fiesta_ensemble_service_test.dart`
(forme v2 figée, v1 ignorée, copies « (2) », duplication d'un fourni),
`test/providers/fiesta_freeze_test.dart` (abandon d'une partie v1),
`test/screens/fiesta_ensembles_flow_test.dart` (bug du nom),
`test/providers/fiesta_two_words_test.dart` (plus de plafond, incompatibilité). Retirés : tests de
plafond (`canAdd maxPerTurn`, Q8), test « oneAnswer reprise de l'ensemble ». Suite complète verte
(231 tests).

## Format attendu

Par finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, affirmation vérifiable,
scénario de reproduction, correction suggérée (de préférence en simplifiant la racine). Conclure
par READY / NOT READY. Parité Android ↔ iOS à vérifier explicitement.
