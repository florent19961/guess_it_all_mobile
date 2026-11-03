# Help wiring: fixes after review r1

Review: `help-wiring-review-r1.md` (Opus, NOT READY: 1 MAJOR, 7 MINOR).

| # | Decision | Fix |
|---|---|---|
| M1 | Fixed in the kit (main b592f11) | `claim({gameId, playerId, screen})` with a persisted first game. The game and verification screens pass `provider.game.gameId`; null (a game from before the update) = no automatic help. `finishFirstGame` stays on the results screen. |
| m1 | Accepted as residue (lead arbitration) | The Fiesta ranking stays implied by the order of « 1 parmi 3 » and by the catch-up seconds: that is the mechanic itself. |
| m2 | Fixed | `turn_screen`: the lifecycle sets `_wentBackground`. `_whilePaused` resumes only if the clock was running AND the app never left the foreground. Otherwise the clock stays paused and the player resumes it. |
| m3 | Fixed | game and verification screens: `_helpPending` is true until `claim` returns. « Commencer le tour » and « Valider » are ignored meanwhile, so the help is never used up without being seen. |
| m4 | Fixed | game_mode: a `_busy` guard (try/finally) around the Fiesta tutorial, so there is a single tutorial and a single navigation. |
| m5 | Fixed | « Une seule réponse » badge: the text follows `_constraints`. With « Interdit de passer » the word is burnt; otherwise you pass it. The « (pénalité de passe) » parenthesis is gone, so it stays correct with a free pass. |
| m6 | Flagged, out of scope | « Commence » after a round that ended at 0 s: provider behaviour, not changed. |
| m7 | Partly fixed | `transitionHelp(fiesta:)` inserts the Fiesta steps itself (no more take/skip). `_roundRule` removed: the hero reuses `AppConstants.roundDescriptions`. Raw colors replaced by AppColors / Colors.white. `FiestaSetupScaffold` takes an `onHelp` callback (no more widget→screen import). Not done: inlining the 4 hero text widgets (not requested). |

No new tests: these are UI guards, and the per-player logic belongs to the kit.
