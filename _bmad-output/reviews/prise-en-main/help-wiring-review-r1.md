# Help wiring r1: Opus review (standing in for Codex)

Scope: `help-wiring-patch-r1.diff` (0ad6feb..) and `help-wiring-patch-r1b.diff` (transition redesign),
worktree `feat/help-wiring` @ 854fb73. Read-only. `flutter analyze lib`: no new warning, and no
info-level issue on a changed line (the remaining infos predate this lane). No widget test covers
game, turn, verification, transition or ModifierBadge, so everything below comes from reading the code.

Scoring logic: untouched (no change to `game_provider` or the models). Confirmed.

## Verdict: NOT READY (1 MAJOR, 0 BLOCKER)

The live-score hiding is clean in Classique. The clock wrapper is correct. The transition is correct,
including the gating. The one MAJOR is where the first game ends, which breaks Florent's rule 2 in a
realistic scenario. The fix is small.

---

## MAJOR

### M1. An abandoned first game never counts as "the first game", so auto help comes back in later games
- `lib/screens/results_screen.dart:33` (`FirstGameHelp.finishFirstGame()` in initState) together
  with `lib/widgets/help/first_game_help.dart:19-22`.
- **Abandon scenario.** A new group starts its first game, plays a few turns, then goes Home and
  starts a "real" game, or relaunches the app the next day. `guessItAll_firstGameDone` is still
  false, because the only writer is the results screen, and `endGame` / word_history are not written
  on abandon either. Every player whose id is not in the in-memory `_shown` set gets the pre-turn and
  verification help again in game 2, and in game 3 too, until a game reaches the results. Rule 2 says
  "ONLY in the first game on this phone… never in later games".
- **Kill scenario.** `_shown` lives in memory only. After a kill during the first game, every player
  who already saw the help gets it again on the next pre-turn and verification. The kit documents this
  as minor, but it breaks "once per player per screen".
- **Fix (in the kit, one place).** Bind the first game to its `gameId`. On the first `claim`, persist
  `firstGameId = currentGameId` together with the `_shown` set (a string list in prefs). A later `claim`
  with a different `gameId` calls `markFirstGameDone()` and returns false. That one change covers abandon,
  kill and resume, which keeps the same gameId and so stays the first game. Results can still call
  `finishFirstGame()`. Alternative with no new key: call `finishFirstGame()` when a new game is created
  while a previous game has history. That covers abandon but not the kill re-show.
- If Florent accepts that "first game" means "first *completed* game", downgrade to MINOR and record
  that wording in WIRING.md.

---

## MINOR

### m1. Fiesta still leaks the ranking, and partly the gap (inherent to the mechanic; Florent to arbitrate)
No points are shown anywhere mid-game. Three things still reveal standings:
- `lib/widgets/fiesta/offer_widgets.dart:198-212`: the « Ordre : A → B → C · X (en tête) ne choisit pas »
  chips list every trailing team from last to best. That is the full ranking. The pass-phone sequence
  reveals the same order anyway, so dropping the chips only hides it from people who don't watch.
- `lib/widgets/fiesta/turn_time_cards.dart:94-104` (CatchUpCard): with « +N s » and the k shown in the
  set-up (« +b1 s × écart »), the exact gap is N / k whenever the cap is not reached. Rule 4 explicitly
  keeps the catch-up seconds, so this is by design. It is listed so Florent knows the gap is derivable.
- `offer_widgets.dart:189-191`: « offre moyenne / forte » gives the gap bucket (≤3, ≤7, >7). It is the
  same category as the seconds above.
- Classique: no ordering leak. The old score-sorted cards are gone. `getTeamsSortedByScore` is now read
  only by `results_screen.dart:40`.

### m2. The turn clock resumes as soon as a sheet closes after the app was backgrounded
`lib/screens/turn_screen.dart:89-95` (`_whilePaused`). Scenario: badge sheet or help open, phone call,
come back. The lifecycle pause is a no-op because the clock is already paused. The player taps
« Compris » and `wasRunning == true` resumes the clock right away. Elsewhere the rule is "on ne reprend
PAS automatiquement" (`turn_screen.dart:50-56`). No time is stolen, because the clock was frozen while
away, but the team may not be ready. Fix: set `_lifecyclePaused = true` in `didChangeAppLifecycleState`
and resume in `_whilePaused` only if `wasRunning && !_lifecyclePaused`. Clear the flag on a manual
resume.

Checked and fine: no double start (`resumeTurn` is guarded by `isPaused`). A clock the player paused
is not resumed (`wasRunning` is false). CoachMarks absorbs every tap (`coach_marks.dart:103-105`), so
the pause button cannot be hit under the help. `CoachMarks.show` pushes synchronously, so there is no
paused-but-no-overlay window. A kill while a sheet is open restores a frozen clock.

### m3. Auto pre-turn help is consumed when « Commencer le tour » is tapped first
`lib/screens/game_screen.dart:52-58`. `claim` is async (SharedPreferences). A tap on « Commencer le
tour » during that gap starts the turn, the screen unmounts, `mounted` is false and nothing is shown,
yet the claim already marked the player as served. That player never gets the pre-turn help. Fix:
check `isFirstGameDone()` and `mounted` first, then claim synchronously right before `show`. Or have
`claim` add to `_shown` only once the caller confirms it is showing the help.

### m4. A double tap on « Continuer » (Fiesta) can stack two tutorials
`lib/screens/game_mode_screen.dart:51-58`. Both taps await `hasSeenFiestaTutorial()` before either
marks it, so two `FiestaTutorialScreen` routes open and `goToScreen` runs twice. Fix: a `_busy` bool
on the State, or disable the button while the future is pending.

### m5. The « Une seule réponse » description is wrong under « Pas de passe » and « Passe gratuite »
`lib/screens/game_screen.dart:785-788`: « Une mauvaise réponse : il faut passer (pénalité de passe) ».
With `no_pass` you cannot pass; line 806 already handles that combination in the constraints. With a
free pass, the penalty is 0. Fix: build the text from the same inputs as `_constraints`, or drop the
parenthesis.

### m6. « Commence » after a round that ended with 0 s carried (pre-existing, made visible)
`transition_screen.dart:72-133` is correct by construction. `nextRound` does not touch the team or
player indexes, and the starter shown is the one the next pre-turn shows. That holds for the continuing
team with carried time and in Fiesta, where neither pick-3 nor catch-up changes the starter. But if the
round ends by validating the *expired* word, `turnBonusTime = 0` (`game_provider.dart:1128`). The
transition then announces « Commence : X · Y » with no carried-time tile, and X gets a 0-second
continuation. This is provider behaviour and out of scope. Flag it to Florent; do not fix it in this
lane.

### m7. Quality (thermo-nuclear rubric, diffs only)
- `transition_screen.dart:37-55`: `steps.take(2)` / `skip(2)` silently depend on the order inside
  `transitionHelp`. A reorder in help_content puts the Fiesta steps in the wrong place. Better: have
  `transitionHelp` take an optional `List<CoachStep> fiesta` and insert it itself. Or split it into
  `transitionTopHelp` and `transitionButtonsHelp`.
- `transition_screen.dart:555-634`: `_HeroEyebrow`, `_HeroBig`, `_HeroTitle` and `_HeroText` are four
  one-shot widget classes. Once the M3 state was removed (5c7edf5) there is only one hero. Inline them
  as styled `Text`s in `_Hero` (pass `round`, `title`, `rule`) to save about 70 lines.
- `transition_screen.dart:412-418` `_roundRule` restates `AppConstants.roundDescriptions` in shorter
  form. That is two sources of truth for the rules. Either move the short versions next to the long ones
  in `constants.dart` or reuse the existing text.
- Raw colours `0xFF0F172A`, `0xFFE2E8F0`, `0xFFFDE68A` and `0xFF06281C` (transition 453, 477, 630, 661,
  765) bypass `AppColors`.
- `lib/widgets/fiesta/fiesta_setup_widgets.dart:4` imports `screens/fiesta_tutorial_screen.dart`, a
  widget→screen dependency (layer inversion). Take an `onHelp` callback in `FiestaSetupScaffold`, or
  move `FiestaTutorialScreen.show` into `widgets/help/`.
- The game_mode « ? » opens the Fiesta tutorial even when the user is choosing Classique (interpretation
  1). That is acceptable, but it is not that screen's help: it says nothing about Classique.
- The home « Première partie ? » prompt comes from the kit and is automatic. Rule 2 lists only the
  per-player help and the Fiesta tutorial as automatic. Make sure Florent has accepted it (kit review).

---

## Checks that passed

1. **Live-score leaks.** Grep for `.score`, `scoreByRound`, `getTeamsSortedByScore`, « points »,
   « écart », « menée » and « classement » across game, turn, countdown, verification, transition,
   `widgets/fiesta/*`, `widgets/common/*` (home button, game dialogs) and home « Reprendre ». The only
   score is the turn's points on verification (`verification_screen.dart:122,134`), which is allowed.
   The scores dialog (game_screen) and score block (transition) are fully removed. `PickThreeCard` no
   longer takes `standings`. help_content never talks about a mid-game score: « points » appears only
   in the results, history and ×2 help.
2. **Auto help trigger.** Once per player per screen inside one process: yes. Never for existing users:
   `inferHelpFlagsFromPastGames` is awaited in `runStartupTasks` before `runApp`. Continuation in round
   N+1, back-to-verification and the GameScreen remount (each screen is rebuilt per `currentScreen`,
   `app.dart:60-86`) do not show it again. Abandon and kill: see M1.
3. **Turn clock.** See m2. Otherwise correct.
4. **Transition.** The starter is correct (see m6 for the 0 s edge). The gating « En attente du choix
   de X » is intact: button disabled at `transition_screen.dart:212-220`, and the provider guard at
   `game_provider.dart:1209` is untouched. Reduced motion: `_Hero` checks
   `MediaQuery.disableAnimationsOf`, and nothing else animates. Overflow: all content sits in an
   `Expanded > SingleChildScrollView`, the track is 194 px fixed, tiles use `Expanded`, and the starter
   text is `Flexible`, so nothing overflows at 320 px. At a ×2 text scale the « ✓/3 » glyph in the
   34 px circles is clipped, which is cosmetic. The empty Fiesta cards (catch-up, boost) correctly
   drop their key. M3 transition: unreachable since `isLastRound` → results (`game_provider.dart:1121-1127`).
5. **Leftovers.** No orphan import (analyzer clean on changed lines). `_showAllScoresDialog` and the
   transition's `_showTeamMembersDialog` and score cards are gone with no dangling caller. `Standings`
   is still used by `OfferChoiceBody` and the provider. `getTeamsSortedByScore` is still used by the
   results.
6. **GlobalKeys.** The exclusive branches hold: home « Nouvelle partie », teams ≤2 vs >2, turn
   `Flexible` twoWords vs single. Keys on `Expanded`/`Flexible`/`HomeButton`/`GameBackButton` resolve to
   the child's render box. No static keys.
