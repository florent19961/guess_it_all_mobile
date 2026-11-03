---
story: 2-6-temps-rattrapage-duree-reelle
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ⑥ timer, ① machine à états (+ ② : le temps fait le score)"
collisions: [game_provider.dart, game_state.dart]
depends: [2-5-tirage-symetrique-transition]
model: Fable
---

# 2-6 : Temps du tour (rattrapage, malus de temps, durée réelle)

## User story

En tant qu'équipe menée, je veux du temps en plus au début de la manche suivante, proportionnel à
mon retard. En tant qu'équipe en tête, je veux savoir que je pars avec un peu moins. Et en tant
que joueur qui regarde ses stats, je veux que le temps passé par tour soit juste.

## Périmètre

- **Fonction pure** `composeTurnSeconds(...)` dans `lib/models/fiesta/` : elle rend le total
  **et** le détail ligne par ligne (pour l'affichage de la maquette `cd` / `cd2`). Entrées :
  durée de base (`_settings.turnDuration`), le tour est-il une continuation (et ses secondes
  reportées), rattrapage dû, malus du leader dû, nombre de « malus de 10 s » actifs pour
  l'équipe, plancher.
  - Continuation : **exactement** les secondes reportées, aucun modificateur de temps (Q1, Q5).
  - Plancher : **10 s** après tous les malus (Q4).
- **Rattrapage** (Auto si « Auto-calibrage » est allumé ; Personnalisé si « Rattrapage » est
  allumé, avec les curseurs de l'ensemble) :
  - calculé **à la fin de la manche N**, sur les scores à ce moment-là (`Team.scoreByRound` /
    `Team.score`) ;
  - équipe menée : `min(cap, k × écart avec l'équipe en tête)`, avec `k = b1` après M1 et `b2`
    après M2 (Auto : 3, 5, plafond 30) ;
  - équipe en tête : `min(malCap, mal × écart avec la 2ᵉ)` (Auto : 1, plafond 15 ; Q2) ;
  - égalité (Q3) : rien ;
  - rangé dans `fiesta` comme « dû » par équipe, et **consommé** au premier tour
    **non-continuation** de l'équipe dans la manche (Q1, Q2).
- **Malus de 10 s** : −10 s par instance active sur l'équipe, sur chaque tour non-continuation.
- **Durée réelle** : nouveau champ **optionnel** de `GameState`, `turnAllottedSeconds`, écrit au
  `startTurnTimer`. `timeSpent` (`game_provider.dart:869`) devient
  `(turnAllottedSeconds ?? _settings.turnDuration) - _game.timeRemaining`. Absent (partie
  reprise depuis l'ancienne version) = comportement d'aujourd'hui.
- **Affichage** : carte « Temps du tour » sur `game_screen.dart` (maquette `cd` / `cd2`, une
  ligne par composante, le total) ; carte « Rattrapage » sur la transition (maquette `r2` :
  « Bleue (menée) · 3 s × 6 → +18 s », « Rose (en tête) · 1 s × 6 → −6 s », plafonds rappelés).

## Critères d'acceptation

1. **Étant donné** une partie Classique, **alors** la durée de chaque tour est celle
   d'aujourd'hui (`turnBonusTime ?? turnDuration`, `:515` et `:524`), seconde pour seconde.
2. **Étant donné** Auto, scores 14–8 à la fin de M1, **quand** l'équipe menée joue son premier
   tour non-continuation de M2, **alors** elle a `30 + min(30, 3 × 6) = 48 s`, et l'équipe en
   tête a `30 − min(15, 1 × 6) = 24 s` sur le sien. Les tours suivants de la manche reviennent à
   30 s.
3. **Étant donné** un écart de 12 après M2, **alors** le bonus est plafonné : `min(30, 5 × 12) =
   30`.
4. **Étant donné** la continuation de fin de manche (`pendingBonusTurnId`), **alors** elle garde
   exactement les secondes reportées, et le rattrapage de cette équipe tombe sur son tour
   suivant.
5. **Étant donné** une égalité, **alors** aucun rattrapage ni malus de leader. Le tirage
   symétrique s'applique.
6. **Étant donné** une base de 20 s, un malus de 10 s et le malus du leader de −15 s, **alors** le
   tour dure 10 s (plancher).
7. **Étant donné** une continuation de 7 s terminée à 2 s, **alors** `HistoryEntry.timeSpent`
   vaut 5, et plus 28. **Étant donné** un tour avec rattrapage de 48 s terminé à 10 s, **alors**
   38.
8. **Étant donné** un retour arrière depuis le tour suivant (`canGoBackToVerification`), **alors**
   le rattrapage déjà consommé reste consommé : le tour a eu lieu. **Étant donné** un retour
   arrière depuis la transition, **alors** le rattrapage calculé disparaît, puis revient
   identique à la revalidation.
9. **Étant donné** l'app tuée en plein tour avec rattrapage, **quand** on la rouvre, **alors** le
   reste est juste (`TurnClock` gelé, `suspendGame` / `resumeGame`), et `timeSpent` en fin de tour
   aussi.

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/providers/game_provider.dart` :
  - `startTurn` `:510-520` (aperçu `timeRemaining`, `:515`) et `startTurnTimer` `:522-542`
    (durée réelle, `:524`) : **les deux** doivent appeler la même `composeTurnSeconds` ;
  - fin de manche par mot deviné `:601-625` (bonus = secondes affichées, `:610`) ;
  - `endTurn` `:702-734` (`turnBonusTime` en fin de manche, `:720`) ;
  - `validateWords` : `timeSpent` `:869`, report de fin de manche `:926`, perte du bonus si des
    mots sont refusés `:939-941` ;
  - `getTeamsSortedByScore` `:1245-1262` (le départage par ordre de jeu sert aussi à désigner
    « l'équipe en tête » en cas d'égalité partielle, voir Q3).
- `lib/models/turn_clock.dart` : `TurnClock.running` `:37`, sans modification. La durée composée
  entre par `durationMs`.
- `lib/models/game_state.dart` : `turnAllottedSeconds` (optionnel, sur le modèle de
  `turnBonusTime`, `:80`).
- `lib/models/stats_aggregation.dart:67-75` : consommateur de `timeSpent`, sans modification.
- `lib/screens/game_screen.dart:193-208` (bloc « Temps bonus »), `lib/screens/transition_screen.dart:155-172`.

## Pièges

- **`startTurn` et `startTurnTimer` calculent chacun la durée** (`:515`, `:524`). Si un seul est
  modifié, l'écran d'avant-tour annonce 30 s et le chrono part à 48 s.
- `startTurnTimer` **efface** `turnBonusTime` (`:534`) : c'est ce qui fait de la continuation un
  tour unique. Le « rattrapage dû » doit suivre le même principe : consommé une fois, effacé.
- « Premier tour non-continuation » : se décider sur `pendingBonusTurnId` / `turnBonusTime`
  **avant** que `startTurnTimer` ne les efface.
- `TurnClock.applyPenalty` peut ramener le reste à 0 (`:111-112`) : le plancher ne porte que sur
  la durée **de départ**.
- La pénalité de passe compte dans `timeSpent` (allouée − restante). C'est déjà le cas
  aujourd'hui, ce n'est pas l'objet de la story.
- `GameAnalytics.turnDuration` reste la durée **réglée**, pas la durée composée (2-7 décide du
  reste).

## Tests (règle minimale)

- `test/models/fiesta/turn_time_test.dart` (pur) : critères 2, 3, 5, 6 et la continuation (4).
- `test/providers/turn_time_test.dart` (ajouts) : critère 7 (bug reproduit : continuation de 7 s
  → `timeSpent` = 5) et critère 1 (Classique inchangé). Les tests existants du fichier passent
  sans modification.

## Recette device (Florent, Android + iOS)

1. Partie Fiesta Auto, 2 équipes, creuser un écart en M1. Sur la transition, lire la carte
   Rattrapage. En M2, l'avant-tour de chaque équipe affiche le bon total et le chrono part de ce
   total.
2. Finir M1 avec du temps restant : la continuation garde ses secondes, sans bonus.
3. En plein tour avec rattrapage : verrouiller l'écran 20 s, puis revenir. Le reste n'a pas bougé.
   Même chose avec un appel entrant (iOS) ou en passant l'app en arrière-plan (Android).
4. Écran Stats en fin de partie : le temps moyen par mot est plausible.
