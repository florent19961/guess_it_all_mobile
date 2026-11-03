# Revue r1 — story 2-5 « Tirage symétrique, transition, annonces avant le tour » (tier risqué : machine à états)

Tu es le reviewer Opus adversarial de la lane. Tu lis **le patch** `2-5-patch-r1.diff` (même
dossier), calculé contre `1061923` (pointe de `feat/fiesta-2-4`, elle-même sur 2-2 ; la lane est
empilée dessus) — jamais `git diff` toi-même. Tu lis le code **avant** la spec, puis tu
confrontes. Rapport dans `2-5-review-r1.md` (même dossier).

## Objectif de la story

Spec : `_bmad-output/specs/fiesta/2-5-tirage-symetrique-transition.md` (AC 1 à 8). Epic :
`_bmad-output/specs/fiesta/epic-fiesta.md`, Q5, Q8, Q9, Q16. Maquette : écrans `r1`, `cd`,
`turn`, `r2` (partie basse), `malus`.

Au début de chaque manche, des modificateurs « pour toutes les équipes » (fixés + tirage) entrent
dans `fiesta.active` ; la transition montre ceux de la manche suivante avant « Manche suivante » ;
le jeu montre « Actif ce tour », le tour des badges sous le chrono ; un plein écran révèle les
malus. Aucun **effet** (2-6, 2-8, 2-9, 2-11).

## Décisions déjà prises (ne pas rouvrir)

- Q8 : le tirage symétrique passe d'abord dans le plafond de 2 (vs offres / cadeaux, plus tard).
- Q9 : Auto = 1 ou 2 (50/50), une fois par manche. Pas de relance.
- Q16 : « fixé sur la manche N » = toutes les équipes, toute la manche N, en plus du tirage.
- « Tirage pour tous allumé » = `symmetric && drawCount > 0` (définition partagée avec 2-3/2-4).
- Graine déterministe `(gameId, manche)`. `draw`, `mime_*` jamais en M1/M2.
- Types publics de 2-2 inchangés (`FiestaRules`, `FiestaState`, `ModifierInstance`, `canAdd`).
- Tests au minimum, pas de test de widget.

## Interprétations de l'implémenteur (à challenger)

1. **Tirage de la manche suivante recalculé, jamais stocké** (la spec suggérait de le ranger dans
   `fiesta` en fin de manche). `nextRoundModifiers` le recalcule depuis `(rules, gameId, manche)` ;
   `nextRound` le pose dans `active`. Raison : la graine suffit pour le retour arrière et l'app
   tuée, et stocker exigeait un champ de plus dans `FiestaState`. Rien ne change dans le JSON.
2. **Fixés avant le tirage** dans le plafond (la spec veut un tirage compatible avec les fixés).
3. **`block_guesser` exclu** du tirage pour tous (cible joueur), même en Personnalisé réglé sur
   « tiré pour tous ».
4. **Graine FNV-1a** sur `'$gameId#$round'`, pas `String.hashCode`. `gameId` nul → `''`.
5. `nextRound` retire les instances `scope == round` dont `round < nouvelle manche` ; celles de
   portée tour restent (2-8).
6. **Révélation des malus** : plein écran (route `fullscreenDialog`) avant le compte à rebours, au
   **premier tour de chaque équipe dans la manche** (aucune entrée d'historique à son nom dans la
   manche), un écran par malus. Dérivé de l'historique, rien de persisté.
7. Avant le tout premier tour : alerte « Une seule réponse » + carte « Tirage de la manche 1 » ;
   ensuite « Actif ce tour » (badges + « Une seule réponse » si allumée). Bloc défilant
   (`Flexible` + scroll) pour ne pas déborder.
8. Sur la transition, la carte de tirage est ajoutée **dans** la zone défilante des scores.
9. Auto : charges = `defaultCharges` du catalogue ; Personnalisé : `setting.charges`.

## Questions précises

- **Relance cachée** : existe-t-il un chemin où le tirage montré sur la transition diffère de
  celui posé par `nextRound` (retour arrière depuis le jeu de M2 vers la vérification de fin de
  M1, app tuée entre les deux, `gameId` nul sur une vieille partie reprise) ?
- AC1 : une partie Classique produit-elle exactement l'état d'aujourd'hui dans `startGame`,
  `validateWords`, `nextRound` (le `copyWith(fiesta: null)` garde-t-il `null`) ?
- Plafond / incompatibilités : un ensemble Personnalisé avec 3 fixés sur la même manche, ou des
  fixés incompatibles entre eux, donne-t-il un résultat sûr ?
- La continuation de fin de manche (`pendingBonusTurnId`) : le tirage de la nouvelle manche
  s'applique-t-il bien à ce tour (badges, révélation) ?
- `MalusReveal.showAll` : contexte démonté, double tap sur « Commencer le tour », retour système
  Android pendant la révélation, geste iOS.
- `turn_screen` reconstruit chaque seconde : aucun aléatoire dans `build` ?
- Valeur des tests : chaque assertion mord-elle (mutation : `Random()` non graine, oubli du
  filtre `round3Only`, oubli du retrait des instances de M1) ?

## Format attendu

Pour chaque finding : sévérité (BLOCKER / MAJOR / MINOR / NIT), `fichier:ligne`, scénario
concret, correction proposée. Verdict final : READY ou NOT READY.
