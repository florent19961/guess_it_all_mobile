---
story: 2-7-analytics-archive-recap
epic: epic-2-mode-fiesta
status: ready-for-dev
tier: "R ⑤ intégrité analytics (+ ③ : champs additifs dans des blobs persistés)"
collisions: [analytics_service.dart, game_provider.dart, game_state.dart, "models: word_event, game_analytics, game_result"]
depends: [2-5-tirage-symetrique-transition, 2-6-temps-rattrapage-duree-reelle]
model: Opus
---

# 2-7 : Analytics, archive et récap des résultats

## User story

En tant que Florent, je veux savoir quels modificateurs étaient actifs quand un mot a été joué,
et quel mode avait chaque partie. Ainsi, je pourrai recalibrer les poids « au doigt mouillé ». En
tant que joueur, je veux voir en fin de partie ce qui s'est passé : tirages, rattrapages, bonus
utilisés.

## Périmètre

- **`WordEvent`** (`lib/models/word_event.dart`) : champ **optionnel** `modifiers`
  (`List<String>?`, ids du catalogue actifs pour l'équipe qui joue). Absent = Classique ou
  événement écrit par l'ancienne version. Lecture tolérante dans `tryFromJson` (`:120-147`).
- **`AnalyticsService`** : `onWordShown` (`:150-178`) reçoit les modificateurs, mémorisés comme
  `_lastRound` / `_lastTurn` (`:32-37`) et recopiés par `_recordEventWithDuration` (`:236-256`),
  `onWordInvalidated` (`:196-213`) et `onWordValidatedAsGuessed` (`:216-233`). **Le provider**
  passe la liste (`_trackWordShown`, `game_provider.dart:545-559`).
- **`GameAnalytics`** (`lib/models/game_analytics.dart`) : champs optionnels `gameMode`
  (`'classique'` | `'fiesta_auto'` | `'fiesta_custom'`) et `fiestaRules` (résumé JSON des règles
  gelées), passés par `startGame` (`analytics_service.dart:48-76`, appelé depuis
  `game_provider.dart:476-485`). Lecture tolérante dans `fromJson` (`:262-295`), qui fait par
  ailleurs des casts durs : **ne pas** en ajouter pour les nouveaux champs.
- **`HistoryEntry`** (`lib/models/game_state.dart:3-58`) : champ optionnel `modifiers` (ids actifs
  ce tour), et le détail du temps alloué de 2-6 si c'est utile au récap.
- **`GameResult`** (`lib/models/game_result.dart`) : champs optionnels `mode` et `modifierRecap`
  (lignes de texte déjà formées, ou structure simple), remplis par `_archiveGameResult`
  (`game_provider.dart:1037-1062`). Lecture tolérante dans `tryFromJson` (`:118-145`).
- **Écran Résultats** (`lib/screens/results_screen.dart`, maquette `results`) : carte
  « Modificateurs de la partie » sous les détails par manche, uniquement en Fiesta. Contenu :
  tirage par manche, rattrapages, choix 1 parmi 3, bonus utilisés, joueurs bloqués. Une section
  se masque tant que la story qui la remplit n'est pas mergée.
- **Stats** : rien n'est exclu, la difficulté initiale des mots ne change pas. `computeStats`
  (`game_analytics.dart:127`) et `WordHistoryService` restent tels quels.

## Critères d'acceptation

1. **Étant donné** une partie Classique, **alors** les blobs `guessItAll_analytics_<id>` et
   `guessItAll_game_results`, et les documents Firestore, sont **identiques** à aujourd'hui
   (aucune clé nouvelle, même pas `null`).
2. **Étant donné** une partie Fiesta avec « Malus de 10 s » tiré en M2, **quand** un mot est
   affiché puis deviné en M2, **alors** les événements `shown` et `guessed` portent
   `modifiers: ['minus_10s']`.
3. **Étant donné** des analytics écrites par la version en store (sans `modifiers` ni
   `gameMode`), **quand** on les relit (`loadAllGames`, `finalizeOrphanedGames`), **alors** elles
   se lisent toutes.
4. **Étant donné** une partie Fiesta reprise après un kill (`resumeGame`,
   `analytics_service.dart:88`), **alors** les événements suivants portent toujours leurs
   modificateurs. On ne dépend pas d'un état mémoire perdu au kill.
5. **Étant donné** la fin d'une partie Fiesta, **alors** `GameResult` porte `mode` et le récap, et
   l'écran Résultats affiche la carte « Modificateurs de la partie ».
6. **Étant donné** `computeStats`, **alors** un mot joué sous modificateur compte exactement comme
   avant (même compteurs, même difficulté).

## Fichiers et lignes (vérifiés sur `de3c8af`)

- `lib/models/word_event.dart:16-39` (champs, constructeur), `:41-86` (fabriques), `:88-99`
  (`toJson`), `:120-147` (`tryFromJson`).
- `lib/services/analytics_service.dart:30-37` (état de suivi), `:48-76` (`startGame`),
  `:138-145` (`_clearTrackingState`), `:150-256` (suivi), `:261-283` (`saveCurrentGame`, blob
  **non enveloppé** : clé `guessItAll_analytics_*`).
- `lib/models/game_analytics.dart:40-90` (champs), `:93-124` (`create`), `:213-240` (`copyWith`),
  `:242-260` (`toJson`), `:262-295` (`fromJson`).
- `lib/services/firebase_sync_service.dart:164-176` : envoie `game.toJson()`. Les règles
  Firestore (`FIREBASE.md:183-187`) ne valident que `userId` et `gameId` : les champs additifs
  passent.
- `lib/providers/game_provider.dart` : `_initializeAnalytics` `:434-486`, `_trackWordShown`
  `:545-559`, `validateWords` `:820-969` (entrées d'historique `:878-904`), `_archiveGameResult`
  `:1037-1062`.
- `lib/screens/results_screen.dart:219` (`_buildDetailedScores`) : insérer la carte après.

## Pièges

- **`GameAnalytics.copyWith`** (`:213-240`) sert à `addEvent`. Un nouveau champ oublié dans
  `copyWith` disparaît **au premier événement**, en silence.
- `_recordEventWithDuration` remet à zéro `_lastShownWord` (`:254-255`), mais pas `_lastRound`.
  Les modificateurs doivent suivre `_lastRound`, pas `_lastShownWord`, sinon `onWordInvalidated`
  (vérification, après le tour) perd l'étiquette.
- Les analytics ne sont **pas** restaurées par le retour arrière (comportement d'aujourd'hui) :
  ne pas essayer de le corriger ici.
- 2-11 réécrira le suivi « un seul mot affiché » (`:32-33`, `:238`) pour les deux cartes : garder
  le changement d'ici minimal, pour ne pas compliquer ce chantier.
- Écrire `modifiers` seulement s'il est non nul (critère 1).

## Tests (règle minimale)

- `test/services/analytics_resume_test.dart` ou un nouveau `test/models/word_event_test.dart` :
  critère 3 (relecture d'un blob sans les nouveaux champs) et aller-retour avec `modifiers`.
- Un test provider ou service : critère 2 (l'étiquette arrive jusqu'à l'événement), en couvrant
  aussi `invalidated` (le piège `_lastShownWord`).
- `test/services/game_history_test.dart` (ajout) : `GameResult` sans `mode` se relit (critère 3).

## Recette device (Florent, Android + iOS)

1. Jouer une partie Fiesta complète, puis lire la carte « Modificateurs de la partie » sur les
   résultats.
2. Console Firestore : le document de la partie porte `gameMode` et les `modifiers` des
   événements. Une partie Classique jouée juste après n'a aucun nouveau champ.
3. L'Historique liste les deux parties normalement.
