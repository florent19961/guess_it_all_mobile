# models/

Modeles de donnees immuables avec pattern `copyWith()` et serialisation JSON.

## Fichiers

| Fichier | Classe(s) | Role |
|---------|-----------|------|
| `player.dart` | `Player` | Joueur (id, name, words). Factory `Player.create()` |
| `team.dart` | `Team` | Equipe (id, name, playerIds, score, scoreByRound[3]) |
| `game_settings.dart` | `GameSettings` | Config partie : nb equipes/joueurs, wordChoice, totalWords, turnDuration, passPenalty, categories, difficultes, `fiestaEnabled` (dernier choix Classique / Fiesta ; cle absente ou mal typee = Classique), `replayFiesta` (regles gelees d'une partie rejouee, en attente de lancement ; cle omise si nulle, illisible = nulle) |
| `score_timeline.dart` | `ScoreTimeline`, `buildScoreTimeline`, `revealHeadline` | Données pures de la révélation des scores : score cumulé par équipe à chaque entrée d'historique (continuations comprises), manches, cartouches jouées placées par (tour, manche, équipe : une continuation partage son numéro de tour avec le tour suivant), sinon en fin de manche ; annonce du vainqueur (`winnerLine`, verbe accordé, aussi dans l'historique) |
| `game_state.dart` | `GameState`, `HistoryEntry` | `GameState.hasUnreadableFiesta(json)` : clé `fiesta` présente mais illisible (autre format que v4) — reprise abandonnée, retour arrière refusé, jamais relue en Classique. Etat complet de la partie en cours : ecran, round, tour, pools de mots, scores, timestamps, snapshots de validation. `turnAllottedSeconds` = durée de **départ** réelle du tour (continuation, bonus et malus de temps), base de `HistoryEntry.timeSpent` ; nul = partie d'une version antérieure → `turnDuration`. `HistoryEntry.pointsScored` (optionnel) : écrit seulement s'il diffère du nombre de mots (×2) ; absent = un point par mot ; `points` est la seule source de « Évolution des scores » |
| `game_analytics.dart` | `GameAnalytics`, `DeviceInfo` | Analytics completes d'une partie pour Firebase (gameId, events, wordMetadata, wordStats). Fiesta : `gameMode`, `fiestaRules` (clés absentes en Classique ; recopiés par `copyWith`, sinon perdus au 1er event) |
| `word_event.dart` | `WordEvent`, `WordEventType`, `PassEvent` | Evenement atomique : shown/guessed/passed/expired/invalidated avec contexte (round, turn, team, player). Fiesta : `modifiers` (clé absente en Classique) |
| `game_result.dart` | `GameResult`, `TeamResult`, `ModifierRecapItem` | Partie archivée pour l'historique. `tryFromJson` ne lève jamais : un champ au mauvais type ne coûte que son entrée. Fiesta : `mode`, `modifierRecap` (clés absentes en Classique) ; le récap est archivé en **faits** (`{kind, round, catalogId?, teamId?, chooserId?, seconds?}`), jamais en phrases ; fait illisible ignoré seul. `setup` (optionnel) : `GameSetupSnapshot` pour « Rejouer » depuis l'historique ; absent des archives antérieures |
| `game_setup_snapshot.dart` | `GameSetupSnapshot` | Réglages (`GameSettings`) + `FiestaRules?` d'une partie archivée, sans les mots. Lecture tolérante : illisible → `null` (Fiesta illisible invalide tout le snapshot) |
| `word_stats.dart` | `WordMetadata`, `WordRoundStats`, `WordStats` | Metadonnees mot (category, difficulty, language), stats par manche et agregees |
| `category_metadata.dart` | `CategoryMetadata` | Metadonnees categorie multilingue (id, icon, noms, locales) |
| `fiesta/modifier_catalog.dart` | `ModifierDef`, `kModifierCatalog`, `kModifierIncompatibilities`, `kCartridgeOnlyIds`, enums `ModifierNature/Scope/Target` | Catalogue Fiesta (18 ids **figés**, du code, jamais persisté ; un ajout se fait **en fin de liste** : `one_answer`, `sounds_only`, `plus_10s`, puis `block_giver`), `modifierById`, `areCompatible` (paires + règle de famille : deux membres `mimeFamily` s'excluent, sauf la paire `sounds_only` / `mime_under_sheet`, compatible dans toutes les combinaisons), `modifierDescription` (texte commun de cette paire quand les deux jouent). `round3Only` = manche 3 seulement (mime) ; `notInRound3` = jamais en manche 3 (« Faire deviner dans une autre langue »), lus par `isEligibleForRound` / `allowedRounds`. `kCartridgeOnlyIds` (tous les bonus, `minus_10s`, `block_guesser`, `block_giver`) : jamais règle de manche ; tout le reste existe dans les 3 menus, `one_answer` compris. 🔴 Tout ajout au catalogue change les tirages et cadeaux des parties suspendues (candidats mélangés par graine) : persister les tirages ou versionner le catalogue avant d'ajouter un modificateur une fois la Fiesta publiée |
| `fiesta/modifier_instance.dart` | `ModifierInstance` | Modificateur actif dans une partie : une règle de manche (cible `both`) ou un malus infligé. `tryFromJson` tolérant (id inconnu → `null`, jamais de défaut inventé). `canAdd(active, candidate)` : compatibilité seulement (plus de plafond). `fromTeamId` (clé `from`, omise si nul) : malus **infligé** par `fromTeamId` à `teamId`, portée tour : il pèse sur le PROCHAIN tour de la cible quelle que soit la manche, puis part à la vraie fin de ce tour. `playerId` : joueur nommé d'un blocage. `fromPlayerId` (`fromPlayer`) : joueur qui l'a envoyé (phrase du piège). `sentTurnIndex` (`sentTurn`) : tour d'envoi, seul cet avant-tour peut l'annuler. `waitsFor(giver)` : blocage sans effet sur ce tour (`block_giver` toujours, `block_guesser` si son joueur fait deviner). Les cartouches détenues ne sont PAS des instances : voir `FiestaState.cartridgesLeft` |
| `fiesta/fiesta_rules.dart` | `FiestaRules`, `ModifierSetting`, enum `EnsembleMenu` | Configuration Fiesta **immuable**, forme **v4** (`format: 4`). `ModifierSetting` = trois réglages INDÉPENDANTS `{always, draw, charges 0-5}`. `FiestaRules` = `{ensembleName?, modifiers, drawCount, allCount, trailingCount (tous 0-5, `kMaxCount`), balance}`. 🔴 `lockReason(id, menu)` : verrouillé = réglages gardés mais sans effet (Toujours sur les 2 autres menus ; mime en Toujours sur les autres mimes partout, sauf la paire ; `no_pass` en Toujours sur `free_pass` et `two_words` en cartouche). Le moteur lit `isAlways`, `drawsFrom`, `chargesOf`, qui l'appliquent ; jamais `settingOf` directement. `tryFromJson` : autre `format` ou compteur hors bornes → `null` ; réglage illisible, hors bornes ou d'id inconnu ignoré seul |
| `fiesta/symmetric_draw.dart` | fonctions pures | Règles de manche : `alwaysForRound` (toutes les manches où il existe) puis `drawForRound` (`drawsFrom`, `drawCount` ; incompatibles sautés, **pas de plafond**), réunis par `roundModifiers(rules, gameId:, round:)`. Graine `drawSeed(gameId, round)` (FNV-1a, stable). `allowedRounds`, `canBeRoundRule` |
| `fiesta/fiesta_state.dart` | `FiestaState`, `ChargeUse`, `EarnedCartridge` | `GameState.fiesta` : `{rules, active, turn, chargesUsed, earned, skips}`. `turn` : `FiestaTurnState` typé (`turn_effects.dart`), vidé à la vraie fin du tour (continuation de fin de manche comprise dans le tour). `chargesUsed` (clé omise si vide) : cartouches dépensées `{catalogId, teamId, round, target?}`, toutes manches. `earned` (clé omise si vide) : cartouches au hasard `{catalogId, teamId, round}`, écrites par `startGame` (M1) et `nextRound` seulement. `skips` (clé omise si vide) : tours sautés par équipe, décalage de sa rotation. `withoutSent` : retire un malus et rend sa cartouche. 🔴 Stock d'une équipe = `cartridgesLeft` : charges de l'ensemble + gagnées − dépensées ; une seule source pour la réserve |
| `fiesta/modifier_recap.dart` | fonctions pures | `kFiestaModeId` (`fiesta_custom` ; les archives `fiesta_auto` restent lisibles), `buildModifierRecap` : récap « Modificateurs de la partie » en faits : tirage recalculé par la graine, cartouches au hasard (`earned`) et cartouches utilisées (`chargesUsed`) relues de l'état ; `formatModifierRecap` forme les lignes depuis les faits (`ModifierRecapLine`, jamais persistée) ; aucun écran ne les affiche depuis le retrait de la carte des Résultats, les faits restent archivés |
| `fiesta/turn_effects.dart` | `FiestaTurnState` + fonctions pures | État du tour typé et immuable (`freePassesUsed`, `charges` par id ↔ clés JSON `doublePoints`/`twoWords`/`freePass`/`plus10s` via `kChargeBonusKeys` (tous les bonus, seulement en cartouche), valeurs `armed`/`spent`, `secondWord`, `secondExpiredWord`, `replaced` : `ReplacedChoices`, ce qu'avait préparé le joueur qui a sauté son tour) : JSON conditionnel, lecture tolérante clé par clé, `afterRoundEnd()` (continuation) ; `canBlockGuesser` (équipe de 3+), `drawOtherCard` (remplaçant ≠ l'autre carte) ; `Cartridge` (une cartouche de la réserve affichée : restantes, raison du grisé ; jamais persistée) |
| `fiesta/round_transition.dart` | fonctions pures | `planRoundTransition` → `RoundTransitionPlan` (règles de N+1 + cartouches au hasard), recalculé sur l'état de fin de N, appliqué une fois par `nextRound` ; `apply` remplace les règles de N par celles de N+1, garde les malus infligés en attente, ajoute à `earned`, et 🔴 REND à l'envoyeur un malus qui devient impossible (`crossesRules`), sauf celui déjà en cours sur le tour qui continue, qui tombe sans rien rendre. `modifiersForTurn` : effets d'un tour = règles de la manche COURANTE (continuation comprise), plus les malus infligés à l'équipe, résolus ICI au tour de la cible, blocages en attente écartés (`waitsFor`) |
| `fiesta/turn_time.dart` | fonctions pures | `composeTurnSeconds` (base + 10 s × `plus10sCount` − 10 s × `minus10sCount`, plancher `kTurnFloorSeconds` = 10 ; continuation = ses secondes + 10 s × `plus10sCount`, sans −10 s ni plancher) |
| `fiesta/cartridge_gifts.dart` | fonctions pures | Cartouches au hasard. `balanceGiftCount` : recette d'« Équilibrer la partie », seuils en constantes (`kBalanceSmallGap`, `kBalanceLargeGap`), à recalibrer. `giftCount` : `allCount` à chaque manche + (après M1 et M2) l'équilibrage ou `trailingCount` pour un non-leader ; égalité et co-leaders : rien de ce second terme. `giftPool` : vivier = tout le catalogue HORS Toujours, compteurs sans effet ; filtres : possible à la manche suivante, ni identique ni incompatible avec ses règles, `block_guesser` seulement si une autre équipe a 3 joueurs. `roundGifts` : vivier mélangé par `giftSeed(gameId, manche, équipe)`, distinctes tant que le vivier le permet puis il repart du début |
| `fiesta/surprise_challenge.dart` | enum `SurpriseChallenge`, `TurnPace`, fonctions pures | Les 5 défis (ordre figé). `trailingTeams`, `slowestPlayer` (critère jamais affiché), `drawChallengeSchedule`, `pickGuessedWord` : déterministes par `gameId`, sans état |
| `fiesta/challenge_plan.dart` | `ChallengePlan`, `ChallengeSide`, `planChallenge` | Le défi qui suit une manche, cartouches comprises (vivier `giftPool`). Recalculé, jamais persisté ; `null` si réglage coupé, pas au programme, déjà terminé, vivier vide ou téléphone arabe sans mot |
| `fiesta/giver_block.dart` | fonctions pures | Le piège d'« Interdit de faire deviner » : les 8 phrases, `giverBlockPhrase`, `giverBlockSeed(gameId, tour)` déterministe |
| `fiesta/fiesta_ensemble.dart` | `FiestaEnsemble`, `kProvidedEnsembles`, `settingsKey`, `nameKey` | Ensemble `{id, rules}` (nom = `rules.ensembleName`). **8 ensembles fournis** (ids `provided_*`, `isProvided`, jamais écrits, seulement duplicables) : Fiesta classique (`kClassicEnsembleId`, présélectionné), Les derniers seront les premiers, Pro Player, Droit au but, Pictionnary, Bilingue, Explosif, Mimeur expert. Aucune règle cachée : tout s'écrit avec les réglages ouverts à tous. `settingsKey` : ce qui joue réellement, hors nom (doublons). `tryFromJson` refuse un id `provided_*` |
| `fiesta/ensemble_validation.dart` | `validateEnsemble`, `ensembleNameError`, `roundsWithoutDraw`, `hasActiveSetting` | Validation **pure** (messages FR) : nom vide / pris, au moins un réglage qui joue, `drawCount` > 0 sans candidat, doublon de réglages (`others`). `roundsWithoutDraw` : avertissement de l'éditeur, pas une erreur. Les combinaisons impossibles ne sont pas jugées : l'éditeur les verrouille, le moteur les écarte |

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
- Forme JSON (Fiesta v4) : `fiesta: {rules: {format: 4, ensembleName?, modifiers: {id: {always, draw,
  charges}}, drawCount, allCount, trailingCount, balance}, active: [{catalogId, scope, target, teamId?,
  playerId?, charges, nature, round, from?, fromPlayer?, sentTurn?}]?, turn?: {}, chargesUsed?:
  [{catalogId, teamId, round, target?}], earned?: [{catalogId, teamId, round}], skips?: {teamId: n}}`.
- 🔴 **Fiesta v4 (2026-11-05, Fiesta jamais publiée)** : tout autre format des règles est **illisible**,
  pas traduit. Ensemble d'un autre format → ignoré (gardé tel quel dans le blob) ; partie Fiesta
  suspendue → **abandonnée** au démarrage par `GameProvider` (retour à l'accueil, joueurs gardés),
  jamais reprise en Classique. `kCurrentSchemaVersion` inchangé. Clés cachées obsolètes (`fiestaMode`,
  `blockedPlayerId`) ignorées. `GameResult` : les faits de genres retirés d'une partie archivée sont
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
