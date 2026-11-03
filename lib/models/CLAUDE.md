# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes |
| `game_state.dart` | `GameState`, `HistoryEntry` | Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta V1 (11 ids **figés**, du code, jamais persisté), `modifierById`, `areCompatible` |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate, {maxPerTurn: 2})` |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, `CatchUpRules`, enums `FiestaMode`, `ModifierArrival` | Configuration Fiesta **immuable** (Auto / Personnalisé, réglage par modificateur, rattrapage, tirage, règles communes). `CatchUpRules.auto` = constantes du mode Auto. `tryFromJson` : structure illisible → `null`, réglage d'id inconnu ignoré seul |
| `fiesta/fiesta_state.dart` | `FiestaState` | `GameState.fiesta` : `{rules, active, turn}`. `turn` est vide pour l'instant (compteurs des stories d'effets) |

## Fiesta — invariants (epic-2)

- **`GameState.fiesta` nul = Classique.** `toJson()` n'écrit **pas** la clé quand nul : le blob
  d'une partie Classique est octet pour octet celui d'avant. `kCurrentSchemaVersion` inchangé.
- **Relecture tolérante** : `fiesta` non-objet ou règles illisibles → Classique ; instance ou
  réglage illisible → ignoré seul (règle `WordEvent.tryFromJson`).
- 🔴 **Champ ajouté après la 1ʳᵉ release Fiesta** : il se lit **clé absente = défaut documenté**
  (`readOr`, `fiesta_rules.dart`) ; seule une valeur présente et mal typée invalide. Sinon une
  mise à jour ferait retomber en Classique toute partie Fiesta en cours.
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
- Forme JSON : `fiesta: {rules: {mode, symmetric, autoCalibrate, ensembleName?, modifiers:
  {id: {active, arrival, startRound, fixedRound?, charges}}, oneOfThree, catchUp: {b1, b2, cap,
  mal, malCap}, drawCount, oneAnswer, carryOver}, active: [{catalogId, scope, target, teamId?,
  playerId?, charges, nature, round}], turn: {}}`.

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
