# Help wiring r1: review brief

Branch `feat/help-wiring`, stacked on `feat/help-kit` (merge-base 16de8d8).
Patch: `help-wiring-patch-r1.diff` (lib only). Tier: standard (UI). Scoring logic is untouched:
no change to `game_provider` or the models. Only displays were removed.

## What was done
- The « ? » button is on home, settings (inline, at the start of the Reset / Advanced row), teams,
  pre-turn (game_screen), turn, verification, transition, results, and on every Fiesta setup
  screen (game_mode, fiesta_choice, fiesta_auto, fiesta_recap through `FiestaSetupScaffold`,
  plus fiesta_ensembles and the ensemble editor).
- Automatic help runs only through `FirstGameHelp.claim` (from the kit, unchanged):
  - pre-turn: `preTurnHelp` only, never the Fiesta part;
  - verification: in a post-frame callback in initState;
  - `finishFirstGame()` is called in the results screen's initState.
- The 3-card Fiesta tutorial opens automatically on « Continuer » in game_mode when Fiesta is
  selected and the tutorial flag is unset.
- Turn screen: `_whilePaused` freezes the TurnClock around the CoachMarks help and around the
  badge sheet. It resumes only if the clock was running before, so a manual pause stays a pause.
- Fiesta badges: `ModifierBadge` takes a `description`. A tap opens a bottom sheet. `.catalog(id)`
  fills the name and description from `ModifierDef`. « Une seule réponse » gets a hand-written
  description, because it is not in the catalogue.
- Live scores removed: the « Scores » button and dialog on game_screen, and the whole Scores
  block on transition (cards sorted by score). Fiesta: the « menée de N points » text in
  PickThreeCard and OfferChoiceBody, and « X s × écart » in CatchUpCard. Kept: the verification
  score for the turn, results, stats and history. Grep: no other read of `team.score`,
  `scoreByRound` or `getTeamsSortedByScore` in a mid-game screen.

## Interpretations (to challenge)
1. **Fiesta setup screens**: the kit has no `help_content` for them. Their « ? » reopens the
   3-card Fiesta tutorial. game_mode gets it too, because it uses the same scaffold.
2. **Transition in Classique**: with Scores gone, the screen keeps the « Manche N ✓ » badge, the
   « Voir les N mots devinés » chip and the CTA. No content was added to fill the space.
3. **CatchUpCard**: keeps the « (en tête / menée) » tag next to the name. It shows an order, not
   a score; the mechanic implies it anyway, and so does « en tête ne choisit pas » in 1 parmi 3.
4. **PickThreeCard**: « X, menée, va choisir une carte. ». No strength label here: the actual
   strength can be one step below the gap's strength (`_strength`), and the offers are not
   computed in this card. OfferChoiceBody shows « Menée · offre moyenne ».
5. **Empty Fiesta cards** (CatchUp or AppBoost with no entries return `SizedBox.shrink`): no
   key, so CoachMarks skips them instead of highlighting a 0×0 hole.
6. **Pre-turn help, « Tour précédent » step**: retitled « Mots du tour précédent ». It targets
   the « N mots » chip: "touche ici… retiens-les : ils reviennent aux manches suivantes".
   `transitionHelp` "Manche suivante" also mentions the Fiesta wait (« En attente du choix »).
7. **Results**: top spacing goes from 24 to 72, so « Résultats » does not slide under the « ? »
   sitting beside the Home button.
8. **Per-player memory**: comes from the kit. It lives in memory only, so an abandoned first game
   restarted with the same players in the same session does not show the help again.
9. Rule 8: nothing platform-specific was added. `showModalBottomSheet` and the CoachMarks route
   behave the same on Android and iOS, and the system back button closes them.
10. PickThreeCard loses its `standings` parameter, which my change left unused.

## Not done (waiting)
- players_screen and history_screen: the lead will give the go once replay-history has merged.
- No tests added: the per-player trigger logic is the kit's, unchanged. The full suite is green
  (216).

## Focus for the reviewer
- GlobalKey placement: keys on `Positioned` widgets (HomeButton, GameBackButton), on `Expanded`,
  and the two exclusive « Nouvelle partie » branches on home.
- `_whilePaused` against the lifecycle pause (app in the background while the sheet is open).
- An auto help in game_screen racing a fast tap on « Commencer le tour » (`_startTurn` checks
  `ModalRoute.isCurrent`).
