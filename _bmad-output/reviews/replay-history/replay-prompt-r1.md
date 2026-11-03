# Review prompt — replay-history r1 (tier RISKY: persisted `guessItAll_game_results`)

Read `replay-patch-r1.diff` (diff against the merge-base with `origin/main`). Do not run `git diff`. Read-only review: write your report to `replay-review-r1.md`, next to this file.

## Goal (Florent, 2026-11-03)
- **A.** In random word mode, the player card in `players_screen` no longer opens the words screen. A non-clickable badge « N mots prêts » replaces « Voir mots ». Custom mode is unchanged.
- **B.** Each card in `history_screen` gets a « Rejouer » button. It pre-fills players, teams, settings and, for a Fiesta game, the `FiestaRules`. It then lands where the end-of-game « Rejouer » lands: the Paramètres screen, or the Fiesta Récap. Words are never replayed.

## Interpretations made by the implementer (challenge them)
1. **Snapshot = `GameSettings` + `FiestaRules?`**, stored as `GameResult.setup` (optional and additive, no `kCurrentSchemaVersion` bump). It is written by `_archiveGameResult` from `_settings`, as they are at the end of the game.
2. **Tolerant read.** Anything unreadable gives `setup == null`, and the old-archive fallback applies. If the Fiesta rules are present but unreadable, the **whole snapshot** is dropped. The intent is to never replay a Fiesta game as Classique while still reusing its settings.
3. **Fallback for an archive without `setup`.** The archive supplies team names, player names, `totalWords` and `turnDuration` (when > 0). Everything else comes from the current settings, with no Fiesta pending, even if `mode` says `fiesta_*`.
4. **`numberOfTeams` / `numberOfPlayers` are always derived** from the recreated teams and players, even when a snapshot exists. Reason: `players_screen` adds or removes players to match `numberOfPlayers`.
5. **An empty archived team name** falls back to « Équipe N ». Player names are recreated as they are, even empty or duplicated: the players screen already validates them.
6. **Reuse of `restartWithSamePlayers`.** `replayFromHistory` sets players, teams, settings and `_pendingFiesta`, then sets `_game = GameState.initial()` before delegating. Without that reset, a suspended game would overwrite the archive's Fiesta rules. The suspended game's analytics are closed (`endGame`), the same as home's « Nouvelle partie ».
7. **Confirmation** only when `game.isGameSuspended`, using home's Annuler/Valider modal. The button is hidden if the archive has no teams.
8. **Random badge:** `wordsCount` is the number of words already drawn. No chevron, and no dimming when there is no name.

9. **Flow (confirmed by Florent).** « Rejouer » lands on the first screen of the normal flow, Paramètres or the Fiesta Récap. From there it goes Paramètres → Joueurs → Équipes, every screen pre-filled, with no screen skipped and no direct launch. On Joueurs, `syncTeamsWithPlayers` keeps the composition because the teams already exist.
10. **Funny team names** (added item). `createTeams` draws distinct names from `lib/utils/team_names.dart` (30 names). No re-roll. Replay keeps the archived names, because `replayFromHistory` does not go through `createTeams`. Note: changing the number of teams in Paramètres calls `createTeams`, which re-draws names. That is the existing behaviour (teams are recreated).

## Specific questions
- Are there any state mutation paths (provider) where a replay leaves an inconsistent state? Examples: `_wordMetadataCache` kept from the previous game, `_currentEditingPlayerId`, a teams screen that recreates teams.
- Rule 7: is an old archive (frozen blob in the test) read and replayed without a crash on every path? Could a `setup` with in-range but obsolete values (a category that no longer exists, an unknown `wordChoice`) break the settings, players or teams screens?
- Rule 8: is there any Android/iOS divergence (modal, safe area)?
- Mutation testing on the 5 tests added (2 model, 3 provider). One mutant was already killed: removing `_game = GameState.initial()` makes the Fiesta test fail.
- Test value: is any test redundant with `test/services/game_history_test.dart`?

## Expected format
Findings classed BLOCKER / MAJOR / MINOR / NIT, each with `file:line`, scenario, and proposed fix. End with a READY / NOT READY verdict.
