# Prise en main — final thermo-nuclear review (PRs #21, #22, #23)

Reviewer: Opus, standing in for Codex (out of quota). Read-only on `main` @ `50b9191`.
Inputs: `pem-cumulative.diff` (48 files), the code in the worktree, the decision journal, the per-lane reviews and fixes.
Rubric: `.claude/skills/thermo-nuclear-code-quality-review/SKILL.md`.
The mockup artifact was not compared pixel by pixel again. The wiring lane review already did that, and this pass covers code and invariants.

## Verdict: SHIPPABLE

There are no BLOCKERs and 1 MAJOR, a copy issue that costs minutes to fix. Rule 7 is clean, live scores do not leak, the turn clock is safe and the round state machine is unchanged.
Tests: the full suite passes (224, `flutter test` via `with-test-slot.sh`), and so do the 6 new test files.

---

## BLOCKER

None.

## MAJOR

### M1. Default team names are plural, and the Fiesta strings around them are singular
- **Where:** `lib/utils/team_names.dart:5-36`. All 30 names start with « Les … ». The strings that broke are:
  - `lib/screens/transition_screen.dart:213`: « En attente du choix de Les Mimes Fous »
  - `lib/widgets/fiesta/offer_widgets.dart:60`: « Les Mimes Fous, menée, va choisir une carte. »
  - `lib/widgets/fiesta/offer_widgets.dart:63`: « Passer le téléphone à Les Mimes Fous »
  - `lib/widgets/fiesta/offer_widgets.dart:391`: « Les Mimes Fous reçoit · … »
  - `lib/widgets/fiesta/turn_time_cards.dart:94` and `OfferChoiceBody`: « (menée) », « Menée · offre … »
- **Scenario:** every Fiesta Personnalisé or Auto game that keeps the default names, which is the default for every new install after this build. The strings were written for « Équipe 1 », which is singular and feminine. Classique is unaffected: « Commence : X », « par X (joueur) » and « reportées pour X » all read correctly.
- **Fix (pick one, about 10 minutes):** (a) drop the article from the list (« Mimes Fous », « Devins du Dimanche »…). Every sentence then reads like « Équipe 1 » again, apart from the gender of « menée ». (b) Rephrase the 5 strings with a colon form that needs no agreement: « Au tour de choisir : X », « Téléphone à : X », « X · menée », « Coup de pouce → X ». Option (a) is simpler and future-proof.

## MINOR

### m1. The turn help explains « Passer » when the « Interdit de passer » malus is active
`lib/screens/turn_screen.dart:505` (`Expanded(key: _passKey`). `WIRING.md` asks for the `pass` key to be left out when the pass is blocked. The step then says « Mot trop dur ? Passe-le » over a disabled button.
**Fix (1 line):** `key: provider.passBlocked ? null : _passKey`. CoachMarks then skips the step.

### m2. `_helpPending` is only cleared on the happy path
`lib/screens/game_screen.dart:58-72` and `lib/screens/verification_screen.dart:35-51`. Today `claim` cannot throw, because every `StorageService` call catches. But if a future change makes it throw, « Commencer le tour » or « Valider » would be dead for the rest of the screen's life, which is a soft-lock in the middle of a game.
**Fix:** `try { … } finally { _helpPending = false; }`.

### m3. The first-game help block is copy-pasted across two screens
The same about 20 lines appear in `game_screen.dart:48-72` and `verification_screen.dart:29-51`: the `_helpPending` flag, the gameId and player lookup, `claim`, then `CoachMarks.show`. **Code judo:** use `FirstGameHelp.showIfFirst(context, screen:, steps:)`, which returns when the help is settled and owns the null-gameId rule. The two screens then shrink to one call plus the flag. This also fixes m2 in one place.

### m4. Clock freezing is threaded through a callback instead of owned by the screen
`modifier_badge.dart:30-33` (`BadgeExplainWrapper`), `ModifierBadges.wrapExplain`, the 3 call sites in `turn_screen.dart:382-398`, plus `_whilePaused` and `_wentBackground`. It is correct today: it pauses only if the clock was running, and never resumes after a trip to the background. But every future overlay on the turn screen has to remember to wrap itself. **Code judo:** `TurnScreen` becomes `RouteAware` (or watches `ModalRoute.of(context).isCurrent`). It pauses on `didPushNext` and resumes on `didPopNext` if it paused the clock itself and the app never left the foreground. `wrapExplain` disappears from the badge API, and badge sheets, help and any later dialog are covered for free. Safe to defer.

### m5. A navigation guard leaks a feature rule into `goToScreen`
`game_provider.dart:1692-1696`. A random-mode special case sits inside the generic navigation method, even though the only caller (`players_screen.dart:386`) is already disabled in random mode. It also does not cover an old `gameState` restored with `currentScreen == words` (pre-game, harmless). **Fix:** delete the guard and rely on the UI, or keep it and accept it. It is not worth a change before release.

### m6. `replayFromHistory` reconstruction logic lives in a 2,110-line provider
`game_provider.dart:1837-1883` (+68 lines in a file already over 1k). Rebuilding players and teams and choosing the settings is a pure function of `(GameResult, current settings, known categories)`. **Code judo:** use `ReplaySetup.from(result, current, knownCategories)` in `models/`. It can be unit-tested without the provider, and the provider keeps about 10 lines of orchestration. Defer.

### m7. Single-use text widgets on the transition screen
`transition_screen.dart:641-723`: `_HeroEyebrow`, `_HeroBig`, `_HeroTitle` and `_HeroText` are 4 classes with one call site each, at 504 → 768 lines. Inline them as `Text` with styles, or use one `_Hero` that takes `eyebrow / big / title / text` strings. This was already flagged as m7 in the wiring review (« not done »). Defer.

### m8. Display fields left dead after hiding the gap
`CatchUpEntry.gap` and `CatchUpEntry.perPoint` (`models/fiesta/turn_time.dart:80-89`) are no longer read by any widget. Keep them only if a test or analytics still needs them, otherwise drop them. Defer.

### m9. The catch-up seconds still reveal the exact gap (accepted, « à valider » in the journal)
`turn_time_cards.dart:96-104` shows `seconds`, which equals `perPoint × gap`. `perPoint` is visible in the ensemble editor (« par point d'écart »), so whoever set up the game can work out the gap. This is consistent with the journal's acceptance that the Fiesta ranking stays deducible. Florent still has to validate it.

### m10. The « existing player » inference has no end-to-end test
`FirstGameHelp.initAtStartup` (`first_game_help.dart:22-26`). The upgrade path for store users is: `guessItAll_word_history` non-empty → `tutorialSeen = firstGameDone = true`. Only `initHelpFlags(playedBefore:)` is tested. Suggested test: prefs shaped like the store build (only `guessItAll_word_history`), then `WordHistoryService().initialize()` and `initAtStartup()`, then expect both flags true. Add a second test with empty prefs, expecting both flags false. Known blind spot: a store user whose word history is corrupt (degraded load), or who never finished a game in v1.0, is treated as new. That user sees the prompt once plus the first-game help, which is acceptable.

### m11. `WIRING.md` is out of date
`lib/widgets/help/WIRING.md:3-4` still says the kit is only wired on Règles and Accueil. The `transition_screen` row still names « Manche suivante » / « Voir les résultats ». The flags table lists 3 of the 5 keys. The file is not shipped. Fix it whenever.

### m12. « Rejouer » in the history has no re-entry guard
`history_screen.dart:132-146`. A double tap with no suspended game runs `replayFromHistory` twice. Both calls converge to the same state, because the second one overwrites the first. The risk is only real if analytics were tracking, which they are not after a finished game. A `_busy` flag like the one in `game_mode_screen` would close it. Defer.

---

## Cross-PR invariants: checks that passed

**Rule 7.** There is no `kCurrentSchemaVersion` bump (0 occurrences in the diff), and there is no change to `GameState`, `Team` or the `GameSettings` JSON. A store install (`v1.0`, which has `guessItAll_word_history` but no `guessItAll_game_results`) upgrades cleanly. The startup task runs after `WordHistoryService().initialize()`, because local tasks run sequentially in `app_bootstrap.dart:29`. It writes the two flags once, and only if they are absent.

**Live scores.** I checked the pre-turn screen (the « Scores » button and its dialog are gone), the turn screen and its pause dialog, the home and end-turn dialogs, verification, the transition, the Fiesta cards (`PickThreeCard`, `OfferChoiceBody`, `CatchUpCard`, `AppBoostCard`), the back-to-verification dialog, the replay pre-fill (fresh teams at 0) and every help text. The only numbers left are the points of the current turn on verification (allowed), the catch-up seconds (allowed, see m9) and the final results. The rules tutorial says the scores are revealed at the end.

**First-game help lifecycle.**
- Fresh install: the flags are written false, so the prompt appears on the first « Jouer ». The first `claim` stores the gameId, and each player sees the pre-turn help and the verification help once.
- Existing user: the flags are written true, so neither the prompt nor the help appears.
- Abandoned first game: the next gameId closes it.
- App killed mid-game: everything is persisted and the same gameId resumes, so nothing is shown twice.
- « Revoir les aides »: resets done, firstGameId and the shown list.
- Replay from history: `GameState.initial()` gives a new gameId at start. If the first game was abandoned, this closes it. If it was finished, `done` is already set.
- Games from before the update (no gameId): no automatic help.
- `ResultsScreen.initState`: closes the first game.

**Turn clock.** The help « ? » and the badge sheets on the turn screen go through `_whilePaused`. It pauses only if the clock is running, and resumes only if the clock was running and the app stayed in the foreground. A pause set by the player stays a pause. The countdown is a separate screen with no help, so the clock never runs under an overlay. The pre-turn screen and the transition have no running clock.

**State machine.** `nextRound`, its guards (screen check, chooser check) and the « M3 → results » routing are untouched. That routing was already direct in v1.0, so no persisted state can sit on a transition after M3. Replay goes through `restartWithSamePlayers` with `_game` reset first, so the Fiesta of the suspended game cannot override the archive's. Fiesta gating (`nextChooserId`) is unchanged.

**iOS / Android (rule 8).** Both tutorials have a « Passer » button (no swipe back on `fullscreenDialog`). CoachMarks always gets a bubble, or skips the step if its target is gone, so iOS never sees a veil with no way out. The Android back button closes the help. The hero animation respects `disableAnimations`.

**Size.** No file crossed 1k lines. The largest increases are the transition screen (504 → 768, see m7) and the provider (+68 on 2,042, see m6). `help_content.dart` (415) is text data and that is fine. 12 screens became Stateful only to hold `GlobalKey`s. That is the price of CoachMarks: acceptable, and documented in WIRING.

## Persisted keys

| Key | Type | Written by | Read tolerance | Default / absent |
|---|---|---|---|---|
| `guessItAll_tutorialSeen` | bool | `initHelpFlags` (once, if absent), `markTutorialSeen` (prompt, rules tutorial) | `_readFlag` try/catch, wrong type → false | written at startup: `playedBefore` |
| `guessItAll_fiestaTutorialSeen` | bool | `FiestaTutorialScreen.show` | same | false → the Fiesta tutorial shows on the first Fiesta (existing users included, as intended) |
| `guessItAll_firstGameDone` | bool | `initHelpFlags` (once), `claim` (another gameId), results screen, `reset` (false) | same | written at startup: `playedBefore` |
| `guessItAll_firstGameId` | String | first `claim`; removed by `reset` | try/catch → null | absent = no first game recorded yet |
| `guessItAll_firstGameHelpShown` | StringList (`screen:playerId`) | `claim`; removed by `reset` | try/catch → `claim` false (safe side: no help) | absent = empty |
| `guessItAll_game_results[].setup` | optional object `{settings, fiesta?}` | `_archiveGameResult` | `GameSetupSnapshot.tryFromJson`: anything out of bounds, unknown or wrongly typed → null → fallback (names, word count, duration if within bounds) | absent in older archives → fallback |
| `guessItAll_settings` | unchanged | « Rejouer » writes the archived settings (validated, categories filtered) | existing | — |
| game session (`Team.name`) | unchanged | `createTeams` draws funny names | existing | — |
| `guessItAll_word_history` | read only (`hasHistory`) | — | degraded → empty | — |

## Fix before release
1. **M1:** team names vs Fiesta grammar. Drop « Les » from the 30 names, or rephrase the 5 strings.
2. **m1:** `key: provider.passBlocked ? null : _passKey` (1 line).
3. **m2:** `finally { _helpPending = false; }` in both screens (2 lines, a guard against a soft-lock), or m3, which covers it.

## Safe to defer
m3 (shared first-game help helper), m4 (RouteAware clock freeze), m5 (`goToScreen` guard), m6 (`ReplaySetup` out of the provider), m7 (hero widgets), m8 (dead `gap/perPoint` fields), m9 (Florent to validate), m10 (upgrade-path test), m11 (WIRING.md), m12 (replay re-entry guard). The journal items still marked « à valider » stay with Florent: team count vs names, empty-history « ? », deducible Fiesta ranking.
