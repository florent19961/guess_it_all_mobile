# Revue du lot 1 `retours-regles` (tier RISQUÉ), round 1

Lecture seule. Lis le patch `_bmad-output/reviews/retours-2026-11-07/lot1-patch-r1.diff` (ne lance pas `git diff`), puis le
code dans le worktree `/home/florent19961/guess-it-all-retours-regles`, branche `feat/retours-regles`. Décisions à ne pas
re-trancher : `_bmad-output/specs/fiesta/retours-2026-11-07.md`, périmètre D1, D2, D3 (valeur de `defaultCharges`
seulement), D4, D5. Écris ton rapport dans `_bmad-output/reviews/retours-2026-11-07/lot1-review-r1.md`.

Hors périmètre, ne pas signaler : UI de la passe gratuite, compteur « Passes gratuites », branchement de `turnLabel`,
icônes (lot 3) ; parcours Paramètres et textes de la carte « Les ensembles » (lot 4) ; animation des scores (lot 2).

## Objectif

Retirer « Deux mots à la fois » du jeu en gardant lisibles les données déjà écrites (CLAUDE.md règle 7 : app publiée, mise à
jour forcée). Changer les ensembles fournis, le tirage des cartouches au hasard, les textes du catalogue.

## Questions précises

1. **Règle 7, chemins de relecture.** Trace un blob ancienne forme (`fiesta.turn.twoWords` armé ou dépensé, `secondWord`,
   `secondExpiredWord`, `replaced.bonuses` avec `two_words`, `earned`, `chargesUsed`, `active`, `rules.modifiers.two_words`,
   snapshot `savePreValidationState`, ensemble enregistré) sur tous les chemins. Un crash, une perte de partie, un mot perdu ou
   dupliqué ? Vérifie chaque `modifierById(...)!`.
2. **Rien à l'écran.** Un chemin qui propose ou joue encore `two_words`, notamment tout ce qui n'itère pas `kModifierCatalog`
   (`bonusesThisTurn`, `_setCharge`, `inflictMalus`, `reuseReplacedChoices`, `spentBonuses`) ? L'historique, lui, doit l'afficher
   sous son nom.
3. **Machine à états.** `markWordAsGuessed`, `passWord`, `endTurn`, `startTurnTimer`, `_fiestaAtRoundEnd` reviennent au mot
   unique : régression par rapport au comportement d'avant 2-11, y compris recyclage des passés, fin de manche, continuation,
   analytics `shown` (le `if (drawn != null)` est devenu un appel gardé dans `_trackWordShown`) ?
4. **Déterminisme du tirage.** `roundGifts` reste une fonction pure de `(gameId, manche, équipe)` et de son vivier ? Le retrait de
   `two_words` au milieu du catalogue change-t-il `roundModifiers` d'une partie suspendue ? L'auteur affirme que non (il était
   réservé aux cartouches, absent des candidats). Contredis si tu peux. Une transition suspendue recalcule un plan différent
   après la mise à jour : est-ce vraiment sans perte ni doublon ?
5. **Bornes.** `allCount` 10 relu et 11 refusé, `_readCount` et `_Stepper`. Autre chose bornait `allCount` ou dépend de `kMaxCount`
   (`settingsKey`, éditeur, duplication d'Explosif) ?
6. **Conformité textuelle.** D1 et D5 : compare mot à mot le tableau de la spec et le catalogue, ainsi que les ensembles fournis et
   `kProvidedSummaries`. Vérifie que les pastilles disent les mêmes règles.
7. **Choix à juger.**
   - `resolveTurn(expiredWords:)` garde sa forme de liste, avec au plus un mot.
   - `kGiftWeights` en record à deux champs pour tenir la consigne « une seule constante ».
   - `turnLabel: 'ne répond pas'` pour `block_guesser`, à préfixer du prénom par le lot 3.
   - `ReplacedChoices.tryFromJson` rend `null` s'il ne reste rien à reprendre.
   - Le prix de défi (`challenge_plan.dart`) reste un mélange uniforme, sans poids : la spec ne vise que `cartridge_gifts.dart`.
   - Le test de réserve d'Explosif en M3 est figé à 14 sortes (les 16 sortes font défiler la zone de 31 px à 360 × 640).

## Grille commune

- Conformité aux décisions, sur Android et iOS (aucun code spécifique plateforme attendu).
- Correctness sur tous les chemins de mutation d'état, code lu avant la spec.
- **Mutation testing obligatoire** sur les tests ajoutés, sans modifier le worktree (copie dans ton scratchpad si tu dois exécuter ;
  tout run passe par `scripts/with-test-slot.sh`, sans pipe). Un test qui nomme une garantie doit l'exercer. Tests ajoutés :
  `test/providers/fiesta_two_words_legacy_test.dart`, `cartridge_gifts_test.dart` (remise, poids), `game_state_test.dart`
  (bornes de `allCount`).
- Valeur des tests : redondant, échafaudage ou obsolète = finding. Tests supprimés : `test/providers/fiesta_two_words_test.dart`,
  `test/screens/turn_screen_two_words_test.dart`, et les cas Deux mots de l'aide. Une couverture utile aux autres cas a-t-elle
  disparu (par exemple `kWordCardLock`, ou la durée par mot en analytics) ?
- Grille `thermo-nuclear-code-quality-review` limitée au diff : reste-t-il du code orphelin de 2-11 ? Un mécanisme sur-dimensionné ?
- Une skill maison ou un CLAUDE.md décrit-il encore un comportement que ce diff change ?

## Format attendu

Verdict `READY` ou `NOT READY` en tête. Puis, par finding : sévérité (BLOCKER, MAJOR, MINOR), `fichier:ligne`, scénario concret de
reproduction, correctif proposé. Termine par les mutations jouées et leur résultat, tuées ou survivantes.
