# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes |
| `game_state.dart` | `GameState`, `HistoryEntry` | Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation. `turnAllottedSeconds` = durée de **départ** réelle du tour (continuation, rattrapage, malus), base de `HistoryEntry.timeSpent` ; nul = partie d'une version antérieure → `turnDuration`. `HistoryEntry.pointsScored` (optionnel) : écrit seulement s'il diffère du nombre de mots (×2) ; absent = un point par mot ; `points` est la seule source de « Évolution des scores » |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats). Fiesta : `gameMode`, `fiestaRules` (clés absentes en Classique ; recopiés par `copyWith`, sinon perdus au 1er event) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player). Fiesta : `modifiers` (clé absente en Classique) |
| `game_result.dart` | `GameResult`, `TeamResult`, `ModifierRecapItem` | Partie archivée pour l'historique. Fiesta : `mode`, `modifierRecap` (clés absentes en Classique) ; le récap est archivé en **faits** (`{kind, round, catalogId?, teamId?, chooserId?, seconds?}`), jamais en phrases ; fait illisible ignoré seul. `setup` (optionnel) : `GameSetupSnapshot` pour « Rejouer » depuis l'historique ; absent des archives antérieures |
| `game_setup_snapshot.dart` | `GameSetupSnapshot` | Réglages (`GameSettings`) + `FiestaRules?` d'une partie archivée, sans les mots. Lecture tolérante : illisible → `null` (Fiesta illisible invalide tout le snapshot) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta V1 (11 ids **figés**, du code, jamais persisté), `modifierById`, `areCompatible` (paires + règle de groupe : « Dessiner » exclut tout `mime`, et inversement). `kOneAnswer` : « Une seule réponse », modificateur de **toute la partie**, hors de la liste par manche ; son état = `FiestaRules.oneAnswer` |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate, {maxPerTurn: 2})` |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, `CatchUpRules`, enums `FiestaMode`, `ModifierArrival` | Configuration Fiesta **immuable** (Auto / Personnalisé, réglage par modificateur, rattrapage, tirage 0-3, `oneAnswer` = « Une seule réponse » pour toute la partie : cochée en Personnalisé, tirée au lancement en Auto ; clé absente relue `true`, l'ancien défaut). `CatchUpRules.auto` = constantes du mode Auto. `tryFromJson` : structure illisible → `null`, réglage d'id inconnu ignoré seul |
| `fiesta/symmetric_draw.dart` | fonctions pures | Modificateurs d'une manche pour toutes les équipes : `fixedForRound` puis `drawSymmetric`, réunis par `roundModifiers(rules, gameId:, round:)`. Graine `drawSeed(gameId, round)` (FNV-1a, stable entre exécutions). `maxModifiersPerTeam` : plafond par équipe et par manche, 2 en Auto, 3 en Personnalisé (fixés, tirage, cartes). `drawsOneAnswer(gameId)` : Auto, 1 chance sur 4, graine de la « manche 0 », appelé par `startGame` |
| `fiesta/fiesta_state.dart` | `FiestaState` | `GameState.fiesta` : `{rules, active, turn, catchUpDue}`. `turn` : `FiestaTurnState` typé (`turn_effects.dart`), vidé à la vraie fin du tour (continuation de fin de manche comprise dans le tour). `catchUpDue` : id d'équipe → secondes dues (négatives = malus du leader), posé par `nextRound`, consommé au premier tour non-continuation. `chargesUsed` (2-9, clé omise si vide) : charges dépensées `{catalogId, teamId, round}`, décompte de la manche en cours + récap « Bonus utilisés » ; `offerChoices` (2-10, clé omise si vide) : cartes 1 parmi 3 choisies `{chooserId, modifier}` — celles dont `modifier.round` = manche suivante forment la file de la transition, `nextRound` les rend actives ; relues pour le récap et `blockingTeam` |
| `fiesta/modifier_recap.dart` | fonctions pures | `fiestaModeId` (`fiesta_auto`/`fiesta_custom`), `fiestaModeLabel`, `buildModifierRecap` : récap « Modificateurs de la partie » **recalculé** en faits (tirage par graine, rattrapage et coup de pouce par `planRoundTransition` sur les scores cumulés par manche), rien de persisté pendant la partie ; `formatModifierRecap` forme les lignes affichées (`ModifierRecapLine`, jamais persistée) |
| `fiesta/turn_effects.dart` | `FiestaTurnState` + fonctions pures | État du tour typé et immuable (`freePassesUsed`, `blockedPlayerId`, `charges` par id ↔ clés JSON `doublePoints`/`twoWords` via `kChargeBonusKeys`, valeurs `armed`/`spent`, `secondWord`, `secondExpiredWord`) : JSON conditionnel, lecture tolérante clé par clé, `afterRoundEnd()` (continuation) ; `chargeAllowance`, `canBlockGuesser` (équipe de 3+), `drawOtherCard` (remplaçant ≠ l'autre carte) |
| `fiesta/round_transition.dart` | fonctions pures | `planRoundTransition` → `RoundTransitionPlan` (tirage + cadeaux + choix + rattrapage de N+1 ; `apply` garde les instances de N pour la continuation) : SEULE source de l'aperçu et de `nextRound`. `modifiersForTurn` : effets d'un tour = instances de sa manche logique (N pour une continuation) |
| `fiesta/turn_time.dart` | fonctions pures | `composeTurnSeconds` (base + rattrapage − malus du leader − 10 s × `minus_10s`, plancher `kTurnFloorSeconds` = 10 ; continuation = ses secondes, sans modificateur) ; `computeCatchUp` (k × écart avec la tête, plafonds, co-leaders tous en tête, égalité = rien) ; `effectiveCatchUp` (Auto → auto-calibrage, Personnalisé → curseurs) |
| `fiesta/offers.dart` | `Standings`, `OfferStrength`, fonctions pures | 2-10 : `kOfferStrength` + `strengthForGap` (≤3 légère, ≤7 moyenne, >7 forte, **à recalibrer**), cran vide → cran inférieur ; `Standings` (leader unique ou `null`, `gapOf`, `choosingOrder` dernière → avant-dernière, vide si égalité ; map construite **dans l'ordre des équipes**) ; `pickThreeOffers(…, roundDraw:, choices:, blockImmuneTeamIds:)` (≤3 cartes utiles : compatibles, plafond `maxModifiersPerTeam`, pas un modificateur que la cible a déjà ; vide = équipe sautée) ; `appBoost(…, roundDraw:)` (Auto : 1 bonus par menée + 1 malus au leader, jamais `block_guesser`). Graine `offerSeed(gameId, round, teamId)` **figée par test**. 🔴 Lane cœur : persister les choix en `Map<chooserTeamId, ModifierInstance>` ; `choices` ne contient que les choix des équipes passées AVANT celle dont on calcule les offres (un malus vise le leader, la clé dit qui l'a choisi) ; prochaine équipe = 1ʳᵉ de `choosingOrder` absente de la map dont les offres ne sont pas vides |
| `fiesta/fiesta_ensemble.dart` | `FiestaEnsemble`, `defaultEnsembleRules`, extensions `copyWith`, `catchUpOn` | Ensemble Personnalisé `{id, rules}` (nom = `rules.ensembleName`, mode toujours `custom`), défauts de la maquette (`mkSet`). Persisté par `FiestaEnsembleService` |
| `fiesta/ensemble_validation.dart` | `validateEnsemble` | Validation **pure** d'un ensemble (messages FR) : bloque l'enregistrement d'une config impossible |

## Fiesta — invariants (epic-2)

- **`GameState.fiesta` nul = Classique.** `toJson()` n'écrit **pas** la clé quand nul. Contrat
  Classique = **règle 7** (ajouts optionnels, absents = défaut, lecture tolérante), pas l'identité
  à l'octet : une partie Classique jouée écrit `turnAllottedSeconds` (2-6), approuvé par Florent.
  `kCurrentSchemaVersion` inchangé.
- **Relecture tolérante** : `fiesta` non-objet ou règles illisibles → Classique ; instance ou
  réglage illisible → ignoré seul (règle `WordEvent.tryFromJson`).
- 🔴 **Champ ajouté après la 1ʳᵉ release Fiesta** : il se lit **clé absente = défaut documenté**
  (`readOr`, `fiesta_rules.dart`) ; seule une valeur présente et mal typée invalide. Sinon une
  mise à jour ferait retomber en Classique toute partie Fiesta en cours.
  🔴 Même règle pour les **ensembles** (`guessItAll_fiestaEnsembles`) : tout champ ajouté à
  `FiestaRules` / `ModifierSetting` / `CatchUpRules` est **optionnel à la lecture**, sinon les
  ensembles des joueurs deviennent illisibles. Le test de format figé
  (`test/services/fiesta_ensemble_service_test.dart`, `frozenBlob`) tombe le cas échéant.
- `ModifierInstance` : une cible `team` / `player` porte **toujours** son `teamId` (assert +
  `tryFromJson`). `canAdd` plafonne **par équipe** : « pour tous » + les siennes.
- **Gel au lancement** : `GameProvider.startGame({FiestaRules? fiesta})` pose une `FiestaState`
  neuve ; `FiestaRules` copie ses collections en lecture seule. Sans argument, `clearFiesta`.
- Tout l'état Fiesta vit ici, jamais dans le provider : persisté par `_saveGameState` et
  restauré par le retour arrière (`savePreValidationState` = `GameState.toJson()`).
- ⚠️ Pour 2-4 : `teams_screen.dart` appelle `startGame()` sans argument, ce qui **efface**
  `fiesta`. Le mode choisi avant le lancement doit être porté jusqu'à cet appel (Q10 : en
  mémoire, hors `GameState`).
- `FiestaState.turn` est un sac `Map<String, dynamic>` non validé (choix de spec). Les stories
  d'effets devraient préférer des champs typés dans `FiestaState` à des clés dans cette map.
- **Tirage déterministe par `(gameId, manche)`** : le tirage de la manche suivante n'est **pas**
  stocké, il est recalculé (`GameProvider.nextRoundModifiers`) ; retour arrière et app tuée
  retrouvent donc le même. Il entre dans `active` au lancement (M1) et à `nextRound` (M2, M3),
  qui retire les instances de portée manche de la manche finie. Jamais de `Random()` non graine
  pour un tirage Fiesta.
- Forme JSON : `fiesta: {rules: {mode, symmetric, autoCalibrate, ensembleName?, modifiers:
  {id: {active, arrival, startRound, fixedRound?, charges}}, oneOfThree, catchUp: {b1, b2, cap,
  mal, malCap}, drawCount, oneAnswer}, active: [{catalogId, scope, target, teamId?,
  playerId?, charges, nature, round}]?, turn?: {}, catchUpDue?: {teamId: int}, chargesUsed?: [...], offerChoices?: [{chooserId, modifier}]}`.
- **Temps du tour** (2-6) : `GameProvider.turnTime` est la **seule** source de la durée de
  départ ; `startTurn` (aperçu) et `startTurnTimer` (chrono, qui écrit `turnAllottedSeconds` et
  consomme `catchUpDue`) la lisent tous deux. `TurnClock` reste la seule autorité sur le temps
  qui court. Les modificateurs de temps ne touchent jamais une continuation (`turnBonusTime`
  posé). En Classique la durée est `turnBonusTime ?? turnDuration`, inchangée.

## Relations

```
GameAnalytics
  ├── DeviceInfo
  ├── List<WordEvent>
  ├── Map<String, WordMetadata>
  └── Map<String, WordStats>
        └── Map<int, WordRoundStats>
```

`GameState` contient tout l'etat de jeu (ecran courant, mots restants, scores). C'est le modele le plus complexe.
