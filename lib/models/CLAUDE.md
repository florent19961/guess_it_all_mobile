# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes, `fiestaMode` (Auto / Personnalise pris en passant en Fiesta ; cle absente ou inconnue = Auto), `fiestaEnabled` (dernier choix Classique / Fiesta ; cle absente ou mal typee = Classique), `replayFiesta` (Personnalise : regles gelees d'une partie rejouee, en attente de lancement ; cle omise si nulle, illisible = nulle) |
| `game_state.dart` | `GameState`, `HistoryEntry` | `GameState.hasUnreadableFiesta(json)` : clé `fiesta` présente mais illisible (autre format que v3) — reprise abandonnée, retour arrière refusé, jamais relue en Classique. Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation. `turnAllottedSeconds` = durée de **départ** réelle du tour (continuation, bonus et malus de temps), base de `HistoryEntry.timeSpent` ; nul = partie d'une version antérieure → `turnDuration`. `HistoryEntry.pointsScored` (optionnel) : écrit seulement s'il diffère du nombre de mots (×2) ; absent = un point par mot ; `points` est la seule source de « Évolution des scores » |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats). Fiesta : `gameMode`, `fiestaRules` (clés absentes en Classique ; recopiés par `copyWith`, sinon perdus au 1er event) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player). Fiesta : `modifiers` (clé absente en Classique) |
| `game_result.dart` | `GameResult`, `TeamResult`, `ModifierRecapItem` | Partie archivée pour l'historique. Fiesta : `mode`, `modifierRecap` (clés absentes en Classique) ; le récap est archivé en **faits** (`{kind, round, catalogId?, teamId?, chooserId?, seconds?}`), jamais en phrases ; fait illisible ignoré seul. `setup` (optionnel) : `GameSetupSnapshot` pour « Rejouer » depuis l'historique ; absent des archives antérieures |
| `game_setup_snapshot.dart` | `GameSetupSnapshot` | Réglages (`GameSettings`) + `FiestaRules?` d'une partie archivée, sans les mots. Lecture tolérante : illisible → `null` (Fiesta illisible invalide tout le snapshot) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, `kCartridgeOnlyIds`, `kRoundRuleOnlyIds`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta (17 ids **figés**, du code, jamais persisté ; un ajout se fait **en fin de liste** : `one_answer`, `sounds_only`, puis `plus_10s`), `modifierById`, `areCompatible` (paires + règle de famille : deux membres `mimeFamily` — les 3 mimes, « Dessiner », « Mimer sous un drap », « Mime de dos », « Bruitages seulement » — s'excluent toujours). `round3Only` = manche 3 seulement (mime) ; `notInRound3` = jamais en manche 3 (« Faire deviner dans une autre langue »), lus par `isEligibleForRound` / `allowedRounds`. `kCartridgeOnlyIds` (tous les bonus, `minus_10s`, `block_guesser`) : jamais règle de manche. `kRoundRuleOnlyIds` (`one_answer`) : jamais cartouche. 🔴 Tout ajout au catalogue change les tirages et cadeaux des parties suspendues (candidats mélangés par graine) : persister les tirages ou versionner le catalogue avant d'ajouter un modificateur une fois la Fiesta publiée |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie : une règle de manche (cible `both`) ou un malus infligé. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate)` : compatibilité seulement (plus de plafond). `fromTeamId` (clé `from`, omise si nul) : malus **infligé** par `fromTeamId` à `teamId`, portée tour : il pèse sur le PROCHAIN tour de la cible quelle que soit la manche (s'il y est permis), puis part à la vraie fin de ce tour. Les cartouches détenues ne sont PAS des instances : voir `FiestaState.cartridgesLeft` |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, enums `FiestaMode`, `ModifierMode` | Configuration Fiesta **immuable**, forme **v3** (`format: 3`). `ModifierSetting` = `{active, rounds ⊂ {1,2,3}, mode, charges}` ; `ModifierMode` : `always` (toutes les manches où il existe, `allowedRounds` ; `rounds` ne compte pas), `draw` (seul à lire `rounds`) ou `cartridge` (`charges` = par équipe pour TOUTE LA PARTIE, 0 = seulement par le coup de pouce), un seul par modificateur. `FiestaRules` = `{mode, ensembleName?, modifiers, drawCount 0-5, boostCount 0-3}` ; `activeSetting(id)`, `copyWith`. `maxCartridges(id)` : borne de `charges`, partagée avec l'éditeur. `tryFromJson` : autre `format` ou compteur hors bornes → `null` ; `boostCount` absent → ancien booléen `trailingBoost` (vrai = 1) ; réglage illisible, hors bornes ou d'id inconnu ignoré seul |
| `fiesta/symmetric_draw.dart` | fonctions pures | Règles de manche : `alwaysForRound` (toutes les manches où il existe, `rounds` ignoré) puis `drawForRound` (« Au tirage » cochés sur la manche, `drawCount`, Auto 1 ou 2 ; incompatibles sautés, **pas de plafond**), réunis par `roundModifiers(rules, gameId:, round:)`. `autoRules(oneAnswer:)` : le mode Auto dans le modèle des ensembles (tout ce qui peut être règle de manche « Au tirage », `one_answer` « Toujours » M1-M3 si tiré, `boostCount` 1). Graine `drawSeed(gameId, round)` (FNV-1a, stable). `drawsOneAnswer(gameId)` : Auto, 1 chance sur 4, graine de la « manche 0 », appelé par `startGame`. `allowedRounds`, `canBeRoundRule`, `canBeCartridge` |
| `fiesta/fiesta_state.dart` | `FiestaState`, `ChargeUse`, `EarnedCartridge` | `GameState.fiesta` : `{rules, active, turn, chargesUsed, earned}`. `turn` : `FiestaTurnState` typé (`turn_effects.dart`), vidé à la vraie fin du tour (continuation de fin de manche comprise dans le tour). `chargesUsed` (clé omise si vide) : cartouches dépensées `{catalogId, teamId, round, target?}`, toutes manches. `earned` (clé omise si vide) : cartouches du coup de pouce `{catalogId, teamId, round}`, écrites par `nextRound` seulement. 🔴 Stock d'une équipe = `cartridgesLeft` : charges de l'ensemble + gagnées − dépensées ; une seule source pour la réserve |
| `fiesta/modifier_recap.dart` | fonctions pures | `fiestaModeId` (`fiesta_auto`/`fiesta_custom`), `fiestaModeLabel`, `buildModifierRecap` : récap « Modificateurs de la partie » en faits : tirage recalculé par la graine, coup de pouce (`earned`) et cartouches utilisées (`chargesUsed`) relus de l'état ; `formatModifierRecap` forme les lignes affichées (`ModifierRecapLine`, jamais persistée) |
| `fiesta/turn_effects.dart` | `FiestaTurnState` + fonctions pures | État du tour typé et immuable (`freePassesUsed`, `blockedPlayerId`, `charges` par id ↔ clés JSON `doublePoints`/`twoWords`/`freePass`/`plus10s` via `kChargeBonusKeys` (tous les bonus, seulement en cartouche), valeurs `armed`/`spent`, `secondWord`, `secondExpiredWord`) : JSON conditionnel, lecture tolérante clé par clé, `afterRoundEnd()` (continuation) ; `canBlockGuesser` (équipe de 3+), `drawOtherCard` (remplaçant ≠ l'autre carte) ; `Cartridge` (une cartouche de la réserve affichée : restantes, raison du grisé ; jamais persistée) |
| `fiesta/round_transition.dart` | fonctions pures | `planRoundTransition` → `RoundTransitionPlan` (règles de N+1 + cadeaux du coup de pouce), recalculé sur l'état de fin de N, appliqué une fois par `nextRound` ; `apply` remplace les règles de N par celles de N+1, garde les malus infligés en attente, ajoute à `earned`. `modifiersForTurn` : effets d'un tour = règles de la manche COURANTE (continuation comprise), plus les malus infligés à l'équipe, résolus ICI au tour de la cible (permis dans la manche, ni en double ni incompatibles avec ses règles de manche ou un malus déjà retenu ; sinon écartés sans effet) |
| `fiesta/turn_time.dart` | fonctions pures | `composeTurnSeconds` (base + 10 s × `plus10sCount` − 10 s × `minus10sCount`, plancher `kTurnFloorSeconds` = 10 ; continuation = ses secondes + 10 s × `plus10sCount`, sans −10 s ni plancher) |
| `fiesta/trailing_boost.dart` | `Standings`, fonctions pures | Coup de pouce à l'équipe menée (Fiesta v3). `Standings.choosingOrder` : équipes NON en tête (co-leaders exclus), vide à égalité générale. `boostPool` : vivier (Personnalisé, les actifs en Cartouche ; Auto, tout ce qui peut être cartouche ; possible en manche suivante, ni déjà en jeu ni incompatible avec ses règles, « Bloquer un devineur » seulement si une autre équipe a 3 joueurs). `trailingBoostGifts` : `boostCount` cartouches au hasard par équipe menée, DISTINCTES (vivier mélangé par la graine `boostSeed(gameId, manche, équipe)`, puis les premières ; moins si le vivier est plus petit), indépendantes des autres équipes ; vivier vide : rien |
| `fiesta/fiesta_ensemble.dart` | `FiestaEnsemble`, `kProvidedEnsembles`, `defaultEnsembleRules`, `defaultSetting`, `settingsKey`, `nameKey` | Ensemble Personnalisé `{id, rules}` (nom = `rules.ensembleName`). **7 ensembles fournis** (ids `provided_*`, `isProvided`, jamais écrits, seulement duplicables) : Fiesta classique (`kClassicEnsembleId`, présélectionné), Pro Player, Droit au but, Explosif, Pictionnary, Bilingue, L'injustice. `settingsKey` : réglages hors nom, modificateurs actifs seulement, manches en Au tirage, cartouches en Cartouche (doublons). `tryFromJson` refuse un id `provided_*`. Plusieurs mimes actifs sont permis ; le moteur reste sûr si un blob viole la règle du « Toujours » (`alwaysForRound` écarte) |
| `fiesta/ensemble_validation.dart` | `validateEnsemble`, `ensembleNameError` | Validation **pure** (messages FR) : nom vide / pris (casse et espaces ignorés, fournis compris), « Au tirage » sans manche ou sur une manche interdite (les manches d'un « Toujours » ne sont pas jugées), exception « seulement en cartouche » en règle de manche, `one_answer` en cartouche, cartouche à 0 sans coup de pouce, coup de pouce sans aucune Cartouche, deux « Toujours » incompatibles qui existent sur une même manche, mime « Toujours » avec un autre mime actif (quel que soit son mode, message nommant les deux), doublon de réglages (`others`) |

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
  `FiestaRules` / `ModifierSetting` est **optionnel à la lecture**, sinon les
  ensembles des joueurs deviennent illisibles. Le test de format figé
  (`test/services/fiesta_ensemble_service_test.dart`, `frozenBlob`) tombe le cas échéant.
- `ModifierInstance` : une cible `team` / `player` porte **toujours** son `teamId` (assert +
  `tryFromJson`). `canAdd` ne juge que la **compatibilité** pour chaque équipe touchée (Fiesta
  v2 : plus de plafond).
- **Gel au lancement** : `GameProvider.startGame({FiestaRules? fiesta})` pose une `FiestaState`
  neuve ; `FiestaRules` copie ses collections en lecture seule. Sans argument, `clearFiesta`.
- Tout l'état Fiesta vit ici, jamais dans le provider : persisté par `_saveGameState` et
  restauré par le retour arrière (`savePreValidationState` = `GameState.toJson()`).
- `startGame()` sans argument **efface** `fiesta` : `teams_screen.dart` lui passe `pendingFiesta`
  (règles en mémoire, hors `GameState` ; dernier choix dans `GameSettings`, `lib/providers/CLAUDE.md`).
- `FiestaState.turn` est un `FiestaTurnState` typé (`turn_effects.dart`) : tout effet de tour
  nouveau y ajoute un champ, lu clé par clé de façon tolérante.
- **Tirage déterministe par `(gameId, manche)`** : le tirage de la manche suivante n'est **pas**
  stocké, il est recalculé (`planRoundTransition`) ; retour arrière et app tuée
  retrouvent donc le même. Il entre dans `active` au lancement (M1) et à `nextRound` (M2, M3),
  qui retire les règles de la manche finie. Jamais de `Random()` non graine
  pour un tirage Fiesta.
- Forme JSON (Fiesta v3) : `fiesta: {rules: {format: 3, mode, ensembleName?, modifiers: {id:
  {active, rounds: [1-3], mode, charges}}, drawCount, boostCount}, active: [{catalogId, scope,
  target, teamId?, playerId?, charges, nature, round, from?}]?, turn?: {}, chargesUsed?:
  [{catalogId, teamId, round, target?}], earned?: [{catalogId, teamId, round}]}`.
- 🔴 **Fiesta v3 (2026-11-05, Fiesta jamais publiée)** : tout autre format des règles (v1 sans
  `format`, v2) est **illisible**, pas traduit. Ensemble d'un autre format → ignoré (gardé tel quel
  dans le blob) ; partie Fiesta suspendue → **abandonnée** au démarrage par `GameProvider` (retour
  à l'accueil, joueurs gardés), jamais reprise en Classique. `kCurrentSchemaVersion` inchangé.
  `GameResult` : les faits de genres retirés (`catchUp`, `choice`) d'une partie archivée sont
  ignorés seuls, l'archive se relit.
- **Temps du tour** (2-6) : `GameProvider.turnTime` est la **seule** source de la durée de
  départ ; `startTurn` (aperçu) et `startTurnTimer` (chrono, qui écrit `turnAllottedSeconds`) la lisent
  tous deux. `TurnClock` reste la seule autorité sur le temps
  qui court. Sur une continuation (`turnBonusTime` posé), seul un `plus_10s` allumé
  s'ajoute au temps reporté ; un `minus_10s` ne s'y réapplique pas. En Classique la durée est `turnBonusTime ?? turnDuration`, inchangée.

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
