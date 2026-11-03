# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes |
| `game_state.dart` | `GameState`, `HistoryEntry` | Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation. `turnAllottedSeconds` = durée de **départ** réelle du tour (continuation, rattrapage, malus), base de `HistoryEntry.timeSpent` ; nul = partie d'une version antérieure → `turnDuration` |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats). Fiesta : `gameMode`, `fiestaRules` (clés absentes en Classique ; recopiés par `copyWith`, sinon perdus au 1er event) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player). Fiesta : `modifiers` (clé absente en Classique) |
| `game_result.dart` | `GameResult`, `TeamResult`, `ModifierRecapLine` | Partie archivée pour l'historique. Fiesta : `mode`, `modifierRecap` (clés absentes en Classique) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta V1 (11 ids **figés**, du code, jamais persisté), `modifierById`, `areCompatible` |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate, {maxPerTurn: 2})` |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, `CatchUpRules`, enums `FiestaMode`, `ModifierArrival` | Configuration Fiesta **immuable** (Auto / Personnalisé, réglage par modificateur, rattrapage, tirage, règles communes). `CatchUpRules.auto` = constantes du mode Auto. `tryFromJson` : structure illisible → `null`, réglage d'id inconnu ignoré seul |
| `fiesta/symmetric_draw.dart` | fonctions pures | Modificateurs d'une manche pour toutes les équipes : `fixedForRound` puis `drawSymmetric`, réunis par `roundModifiers(rules, gameId:, round:)`. Graine `drawSeed(gameId, round)` (FNV-1a, stable entre exécutions) |
| `fiesta/fiesta_state.dart` | `FiestaState` | `GameState.fiesta` : `{rules, active, turn, catchUpDue}`. `turn` est vide pour l'instant (compteurs des stories d'effets). `catchUpDue` : id d'équipe → secondes dues (négatives = malus du leader), posé par `nextRound`, consommé au premier tour non-continuation |
| `fiesta/modifier_recap.dart` | fonctions pures | `fiestaModeId` (`fiesta_auto`/`fiesta_custom`), `fiestaModeLabel`, `buildModifierRecap` : récap « Modificateurs de la partie » **recalculé** (tirage par graine, rattrapage sur les scores cumulés par manche), rien de persisté pendant la partie |
| `fiesta/turn_time.dart` | fonctions pures | `composeTurnSeconds` (base + rattrapage − malus du leader − 10 s × `minus_10s`, plancher `kTurnFloorSeconds` = 10 ; continuation = ses secondes, sans modificateur) ; `computeCatchUp` (k × écart avec la tête, plafonds, co-leaders tous en tête, égalité = rien) ; `effectiveCatchUp` (Auto → auto-calibrage, Personnalisé → curseurs) |
| `fiesta/fiesta_ensemble.dart` | `FiestaEnsemble`, `defaultEnsembleRules`, extensions `copyWith`, `catchUpOn` | Ensemble Personnalisé `{id, rules}` (nom = `rules.ensembleName`, mode toujours `custom`), défauts de la maquette (`mkSet`). Persisté par `FiestaEnsembleService` |
| `fiesta/ensemble_validation.dart` | `validateEnsemble` | Validation **pure** d'un ensemble (messages FR) : bloque l'enregistrement d'une config impossible |

## Fiesta — invariants (epic-2)

- **`GameState.fiesta` nul = Classique.** `toJson()` n'écrit **pas** la clé quand nul : le blob
  d'une partie Classique est octet pour octet celui d'avant. `kCurrentSchemaVersion` inchangé.
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
  mal, malCap}, drawCount, oneAnswer, carryOver}, active: [{catalogId, scope, target, teamId?,
  playerId?, charges, nature, round}], turn: {}, catchUpDue: {teamId: int}}`.
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
