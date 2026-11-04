# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes |
| `game_state.dart` | `GameState`, `HistoryEntry` | `GameState.hasUnreadableFiesta(json)` : clé `fiesta` présente mais illisible (forme v1) — reprise abandonnée, retour arrière refusé, jamais relue en Classique. Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation. `turnAllottedSeconds` = durée de **départ** réelle du tour (continuation, rattrapage, malus), base de `HistoryEntry.timeSpent` ; nul = partie d'une version antérieure → `turnDuration`. `HistoryEntry.pointsScored` (optionnel) : écrit seulement s'il diffère du nombre de mots (×2) ; absent = un point par mot ; `points` est la seule source de « Évolution des scores » |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats). Fiesta : `gameMode`, `fiestaRules` (clés absentes en Classique ; recopiés par `copyWith`, sinon perdus au 1er event) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player). Fiesta : `modifiers` (clé absente en Classique) |
| `game_result.dart` | `GameResult`, `TeamResult`, `ModifierRecapItem` | Partie archivée pour l'historique. Fiesta : `mode`, `modifierRecap` (clés absentes en Classique) ; le récap est archivé en **faits** (`{kind, round, catalogId?, teamId?, chooserId?, seconds?}`), jamais en phrases ; fait illisible ignoré seul. `setup` (optionnel) : `GameSetupSnapshot` pour « Rejouer » depuis l'historique ; absent des archives antérieures |
| `game_setup_snapshot.dart` | `GameSetupSnapshot` | Réglages (`GameSettings`) + `FiestaRules?` d'une partie archivée, sans les mots. Lecture tolérante : illisible → `null` (Fiesta illisible invalide tout le snapshot) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, `kCartridgeOnlyIds`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta (16 ids **figés**, du code, jamais persisté ; un ajout se fait **en fin de liste** : `one_answer` puis `sounds_only` ajoutés par Fiesta v2), `modifierById`, `areCompatible` (paires + règle de famille : deux membres `mimeFamily` — les 3 mimes, « Dessiner », « Mimer sous un drap », « Mime de dos », « Bruitages seulement » — s'excluent toujours). `round3Only` = manche 3 seulement (mime) ; `notInRound3` = jamais en manche 3 (« Faire deviner dans une autre langue »), lus par `isEligibleForRound` / `allowedRounds`. `kCartridgeOnlyIds` (`block_guesser`, `double_points`) : jamais règle de manche. « Une seule réponse » (`one_answer`) est un malus normal (plus de réglage de toute la partie). 🔴 Tout ajout au catalogue change les tirages et offres des parties suspendues (candidats mélangés par graine) : persister les tirages ou versionner le catalogue avant d'ajouter un modificateur une fois la Fiesta publiée |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate)` : compatibilité seulement (plus de plafond). `reserve` (clé omise si faux) : malus « En stock » détenu par `teamId`, sans effet (`modifiersForTurn` l'ignore) jusqu'à la lane 2. Cible `both` = règle de manche (s'applique d'elle-même : « Deux mots » Toujours/Au tirage = deux cartes sans activation), cible `team`/`player` = cartouche |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, `CatchUpRules`, enums `FiestaMode`, `ModifierMode` | Configuration Fiesta **immuable**, forme **v2** (`format: 2`). `ModifierSetting` = `{active, rounds ⊂ {1,2,3}, mode, charges, perGame}` ; `ModifierMode` : `always` / `draw` (« Toute la manche, pour tous ») ou `stock` / `offer` (« Cartouche · un tour »), un seul par modificateur. `FiestaRules` = `{mode, autoCalibrate, ensembleName?, modifiers, drawCount 0-5, pick3Choices 1-3, catchUp}` ; `activeSetting(id)`, `copyWith` ; `kCatchUpOff` / `catchUpOn`. `tryFromJson` : sans `format: 2` (forme v1) ou compteur hors bornes → `null` ; réglage illisible ou d'id inconnu ignoré seul |
| `fiesta/symmetric_draw.dart` | fonctions pures | Règles de manche : `alwaysForRound` puis `drawForRound` (« Au tirage » cochés sur la manche, `drawCount`, Auto 1 ou 2 ; incompatibles sautés, **pas de plafond**), réunis par `roundModifiers(rules, gameId:, round:)`. `stockForRound` : cartouches « En stock » par équipe (bonus par le mécanisme de charges ; malus posés en `reserve`, sans effet jusqu'à la lane 2 ; « pour la partie » = N − dépensées avant, sauf Passe gratuite, toujours par manche). `autoRules(oneAnswer:)` : le mode Auto dans le modèle des ensembles (tout « Au tirage », `one_answer` « Toujours » M1-M3 si tiré). Graine `drawSeed(gameId, round)` (FNV-1a, stable). `drawsOneAnswer(gameId)` : Auto, 1 chance sur 4, graine de la « manche 0 », appelé par `startGame`. `allowedRounds`, `canBeRoundRule` |
| `fiesta/fiesta_state.dart` | `FiestaState` | `GameState.fiesta` : `{rules, active, turn, catchUpDue}`. `turn` : `FiestaTurnState` typé (`turn_effects.dart`), vidé à la vraie fin du tour (continuation de fin de manche comprise dans le tour). `catchUpDue` : id d'équipe → secondes dues (négatives = malus du leader), posé par `nextRound`, consommé au premier tour non-continuation. `chargesUsed` (2-9, clé omise si vide) : charges dépensées `{catalogId, teamId, round}`, décompte de la manche en cours + récap « Bonus utilisés » ; `offerChoices` (2-10, clé omise si vide) : cartes 1 parmi 3 choisies `{chooserId, row, modifier}` (`row` = rangée, absent = 0) — celles dont `modifier.round` = manche suivante forment la file de la transition, `nextRound` les rend actives ; relues pour le récap et `blockingTeam` |
| `fiesta/modifier_recap.dart` | fonctions pures | `fiestaModeId` (`fiesta_auto`/`fiesta_custom`), `fiestaModeLabel`, `buildModifierRecap` : récap « Modificateurs de la partie » **recalculé** en faits (tirage par graine, rattrapage et coup de pouce par `planRoundTransition` sur les scores cumulés par manche), rien de persisté pendant la partie ; `formatModifierRecap` forme les lignes affichées (`ModifierRecapLine`, jamais persistée) |
| `fiesta/turn_effects.dart` | `FiestaTurnState` + fonctions pures | État du tour typé et immuable (`freePassesUsed`, `blockedPlayerId`, `charges` par id ↔ clés JSON `doublePoints`/`twoWords` via `kChargeBonusKeys`, valeurs `armed`/`spent`, `secondWord`, `secondExpiredWord`) : JSON conditionnel, lecture tolérante clé par clé, `afterRoundEnd()` (continuation) ; `chargeAllowance`, `canBlockGuesser` (équipe de 3+), `drawOtherCard` (remplaçant ≠ l'autre carte) |
| `fiesta/round_transition.dart` | fonctions pures | `planRoundTransition` → `RoundTransitionPlan` (tirage + cadeaux + choix + rattrapage de N+1 ; `apply` garde les instances de N pour la continuation) : SEULE source de l'aperçu et de `nextRound`. `modifiersForTurn` : effets d'un tour = instances de sa manche logique (N pour une continuation) |
| `fiesta/turn_time.dart` | fonctions pures | `composeTurnSeconds` (base + rattrapage − malus du leader − 10 s × `minus_10s`, plancher `kTurnFloorSeconds` = 10 ; continuation = ses secondes, sans modificateur) ; `computeCatchUp` (k × écart avec la tête, plafonds, co-leaders tous en tête, égalité = rien) ; `effectiveCatchUp` (Auto → auto-calibrage, Personnalisé → curseurs) |
| `fiesta/offers.dart` | `Standings`, `OfferStrength`, fonctions pures | 2-10 + Fiesta v2 : `kOfferStrength` + `strengthForGap` (≤3 légère, ≤7 moyenne, >7 forte, **à recalibrer**), cran vide → cran inférieur ; `Standings` (leader unique ou `null`, `gapOf`, `choosingOrder` dernière → avant-dernière, vide si égalité) ; `isPickThreeOn` (Personnalisé, un « 1 parmi 3 » coché sur N+1) ; `pickThreeOffers(…, roundDraw:, earlierChoices:, blockImmuneTeamIds:)` → **rangées** (`pick3Choices` × 3 cartes au plus, aucun id repris d'une rangée à l'autre, rangée 0 graine `offerSeed(gameId, round, teamId)` **figée par test**, rangée k graine de `'$teamId#k'`) ; `isUsefulOffer` (compatible, pas déjà subi ; **pas de plafond**) ; `appBoost(…, roundDraw:)` (Auto : 1 bonus par menée + 1 malus au leader, jamais `block_guesser`). Une carte « ×2 / Deux mots » porte 1 charge ; les autres gardent leur effet de manche (lane 1) |
| `fiesta/fiesta_ensemble.dart` | `FiestaEnsemble`, `kProvidedEnsembles`, `defaultEnsembleRules`, `defaultSetting`, `settingsKey`, `nameKey`, `oneMimeAtMost` | Ensemble Personnalisé `{id, rules}` (nom = `rules.ensembleName`). **7 ensembles fournis** (ids `provided_*`, `isProvided`, jamais écrits, seulement duplicables) : Fiesta classique (`kClassicEnsembleId`, présélectionné), Pro Player, Droit au but, Explosif, Pictionnary, Bilingue, L'injustice. Nouvel ensemble = maquette `defaults()`. `settingsKey` : réglages hors nom, modificateurs actifs seulement (doublons). `tryFromJson` refuse un id `provided_*` et passe par `oneMimeAtMost` (garde le 1er « Toujours », sinon le 1er actif) |
| `fiesta/ensemble_validation.dart` | `validateEnsemble`, `ensembleNameError` | Validation **pure** (messages FR) : nom vide / pris (casse et espaces ignorés, fournis compris), actif sans manche, exception cartouche en règle de manche, manche interdite par le catalogue, « 1 parmi 3 » en M1 seule, deux « Toujours » incompatibles sur une manche, doublon de réglages (`others`) |

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
  `tryFromJson`). `canAdd` ne juge que la **compatibilité** pour chaque équipe touchée (Fiesta
  v2 : plus de plafond).
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
- Forme JSON (Fiesta v2) : `fiesta: {rules: {format: 2, mode, autoCalibrate, ensembleName?,
  modifiers: {id: {active, rounds: [1-3], mode, charges, perGame}}, drawCount, pick3Choices,
  catchUp: {b1, b2, cap, mal, malCap}}, active: [{catalogId, scope, target, teamId?,
  playerId?, charges, nature, round}]?, turn?: {}, catchUpDue?: {teamId: int}, chargesUsed?:
  [...], offerChoices?: [{chooserId, row, modifier}]}`.
- 🔴 **Fiesta v2 (2026-11-04, Fiesta jamais publiée)** : la forme v1 des règles (sans `format`)
  est **illisible**, pas traduite. Ensemble v1 → ignoré (gardé tel quel dans le blob) ; partie
  Fiesta suspendue v1 → **abandonnée** au démarrage par `GameProvider` (retour à l'accueil,
  joueurs gardés), jamais reprise en Classique. `kCurrentSchemaVersion` inchangé.
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
