# Epic 2 — mode Fiesta — revue thermo-nucléaire de fin d'epic (Opus)

Périmètre : diff cumulé 2-2 → 2-11 (`epic-cumulative.diff`), code lu dans le worktree de revue à `35e8f2d`.
Grille : `thermo-nuclear-code-quality-review`. Angle : **cross-story**, c'est-à-dire si une garantie posée par une story tient encore après les chemins ajoutés par les suivantes.

Les numéros de ligne renvoient à `35e8f2d`.

Vérifications exécutées :
- `flutter test test/providers test/models/fiesta test/services/fiesta_analytics_test.dart test/models/game_state_test.dart` : **96/96 verts**.
- 1 mutant (tag analytics `two_words` retiré de `_trackWordShown`) : **tué** par `fiesta_two_words_test`. Il a été reverté, l'arbre est propre.

## Verdict

**SHIPPABLE — aucun BLOCKER.**
- La persistance (règle 7), la parité Classique et le payload Firestore sont propres.
- Il y a **4 MAJOR**. **M1, M2 et M4 sont à corriger avant le build store** : chacun coûte moins d'une heure.
- **M3 demande une décision de Florent** avant le build.
- M5 relève de la maintenabilité et peut attendre.

M1 et M2 sont des réglages d'écran qui ne font rien. Leur valeur est persistée dans les ensembles, donc elle sera gelée dès la release : c'est pour ça qu'il faut trancher maintenant.

---

## MAJOR

### M1 — L'interrupteur « Temps reporté de fin de manche » ne fait rien (2-2 / 2-3 / 2-4)

- **Où :**
  - `lib/widgets/fiesta/fiesta_setup_widgets.dart:296-301` : la ligne est éditable.
  - `fiesta_auto_screen.dart:29,77` et `fiesta_ensemble_editor_screen.dart:394` : la valeur est écrite.
  - `FiestaRules.carryOver` : la valeur est persistée.
  - **Aucun lecteur** dans la logique de jeu : `grep carryOver lib` ne renvoie que de l'UI et du modèle.
- **Scénario :** l'utilisateur coupe « Temps reporté » en Auto ou dans un ensemble. En fin de manche, `validateWords` pose quand même `turnBonusTime` (`game_provider.dart:1130`) et la continuation a lieu.
- **Pourquoi c'est cross-story :** l'epic dit « le report de temps de fin de manche est **conservé** » (epic-fiesta.md §Règles communes). Ce n'est pas un réglage. 2-2 a pourtant modélisé le champ, 2-3 et 2-4 l'ont rendu éditable, et aucune story ne l'a branché.
- **Fix, au choix :**
  - **(a) recommandé, fidèle à la spec :** retirer la ligne de `FiestaCommonRulesCard`. On garde le champ dans `FiestaRules` pour la relecture, et on l'ignore.
  - **(b)** le brancher : `turnBonusTime: rules.carryOver ? timeRemaining : null` au chemin fin de manche, plus `pendingBonusTurnId`.
- **Avant la release dans tous les cas :** une fois publié, un `carryOver: false` stocké dans un ensemble changerait de sens le jour où on le brancherait.

### M2 — « Bloquer un devineur » est inatteignable par défaut, et réglable sur deux arrivées sans effet (2-3 × 2-5/2-8/2-10)

- **Où :**
  - `lib/models/fiesta/fiesta_ensemble.dart:44-48` : `defaultEnsembleRules` donne à `block_guesser` (un malus) l'arrivée `ModifierArrival.draw`, dès M1.
  - `fiesta_ensemble_editor_screen.dart:249` : l'éditeur propose les 3 arrivées à tous les modificateurs.
  - `ensemble_validation.dart:27-48` : la validation les accepte.
  - Or `symmetric_draw.dart:30,59,96` (`isForAllTeams`) **exclut** `block_guesser` du tirage et du « fixé ».
  - Et `offers.dart` `_candidates` ne le propose qu'en arrivée `offer`.
- **Scénario :** un ensemble créé par défaut affiche « Bloquer un devineur · Tiré au sort pour tous · dès M1 ». Le modificateur n'arrive **jamais** : il n'est ni tiré, ni fixé, ni proposé. Un utilisateur qui le passe en « Fixé sur M2 » obtient la même chose, sans message.
- **Cause :** la décision de 2-8 (« reste offre seule… aucun code à changer », journal) a été prise après 2-3. Le défaut et l'éditeur de 2-3 n'ont pas été remis à niveau.
- **Fix :**
  - Le défaut d'un modificateur à cible joueur devient `offer` avec `startRound: 2`.
  - L'éditeur n'affiche que « Proposé à l'équipe menée » pour `isForAllTeams(def) == false`, ou `validateEnsemble` refuse draw/fixed avec un message.
  - Test pur dans `ensemble_validation_test`, plus un test du défaut.
  - Aucun ensemble n'est encore en store, donc il n'y a rien à migrer.

### M3 — Un « Bloquer un devineur » de N+1 est brûlé par la continuation de fin de manche (2-8 « un seul tour » × 2-10)

- **Où :**
  - `game_provider.dart:1510` `_fiestaAfterTurn` consomme **toutes** les instances de portée tour de l'équipe à la vraie fin du tour. La vraie fin, c'est la fin de la continuation.
  - `blockableGuessers` et `needsBlockedGuesser` (`:1340`, `:1361`) ouvrent le sélecteur dès la continuation.
  - `offers.dart:144-146` assume ce choix dans un commentaire : « un tour (fin de manche + continuation) ».
  - Le comportement est **figé par un test** : `fiesta_pick_three_test.dart:151`.
- **Scénario :**
  1. L'équipe menée choisit « Bloquer un devineur » contre le leader pour M2.
  2. Le leader est l'équipe qui a clos M1. Avec 2 équipes, c'est une fois sur deux.
  3. Le blocage s'applique à sa **continuation**, qui dure les secondes reportées. Si le dernier mot avait expiré puis été validé à la vérification, la continuation dure **0 s** : `turnBonusTime = timeRemaining = 0`, chemin déjà présent avant l'epic.
  4. La carte est consommée là. Le vrai premier tour du leader en M2 n'est pas bloqué.
- **Variante silencieuse (M2→M3) :** le leader était déjà bloqué sur son tour de fin de M2 (blocage choisi en M1→M2), et un nouveau blocage est choisi contre lui pour M3. `blockedPlayerId` survit dans `fiesta.turn`. Le nouveau blocage n'est alors **ni désigné, ni annoncé**, et il est consommé quand même.
- **Pourquoi c'est un problème :** la définition « un seul tour » (journal 2-8) protège les instances de **N** qui enjambent la fin de manche. Elle est appliquée telle quelle aux instances **posées pour N+1**, et c'est là qu'elle se retourne. La carte « forte » la plus chère du 1 parmi 3 peut ainsi n'avoir aucun effet.
  - `minus_10s` a déjà un traitement spécial (`malusToReveal`, `firstFullTurn`).
  - `block_guesser` n'en a pas.
- **Fix proposé (à faire valider par Florent) :** une instance de portée tour posée pour la manche en cours (`m.round == currentRound`) ne s'applique pas à une continuation et n'y est pas consommée.
  - Il faut savoir qu'on est en continuation **pendant** le tour. `startTurnTimer` efface `turnBonusTime`, donc ce n'est plus dérivable une fois le tour lancé.
  - Le plus simple : poser `fiesta.turn['continuation'] = true` dans `startTurnTimer`. Le blob n'est pas publié, donc il n'y a rien à migrer.
  - `_fiestaAfterTurn` garde alors les instances `scope==turn && round==currentRound` quand le tour était une continuation.
  - `blockableGuessers` les ignore de la même façon.
  - Le test `pick_three:151` s'inverse.

### M4 — `validateWords` n'a pas de garde d'écran (problème d'avant l'epic, aggravé par Fiesta)

- **Où :** `verification_screen.dart:245-248` appelle `savePreValidationState` puis `validateWords`, sans garde. `game_provider.dart:1016` n'en a pas non plus.
- **Scénario :** même course que le double tap sur « Manche suivante », que 2-5 a jugé réel et corrigé à `nextRound:1214`. Un second « Valider » déclenché avant le rebuild :
  1. réécrase le snapshot de retour arrière avec l'état **déjà validé** ;
  2. recrédite les mêmes mots à l'équipe **suivante**, ×2 compris si `isDoublePointsOn`. Un bug Classique déjà présent, désormais doublé ;
  3. en Fiesta, appelle `_fiestaAfterTurn` sur l'équipe suivante **avant qu'elle joue**. Elle perd son `block_guesser` et ses instances de tour.
- **Fix, une ligne :** `if (_game.currentScreen != AppConstants.screenVerification) return;` en tête de `validateWords` et de `savePreValidationState`. Ajouter un test « double validation = un seul crédit », sur le modèle de `fiesta_round_draw_test:174`.

### M5 — Maintenabilité : provider à 2 061 lignes, `fiesta.turn` non typé, ×2 et « deux mots » copiés-collés

- **Taille du provider :** `game_provider.dart` passe de **≈1 466 à 2 061 lignes** (+595).
  - La zone Fiesta, `:1250-1672` (≈420 lignes), est presque entièrement un **modèle de lecture** : une trentaine de getters dérivés de `(_game.fiesta, _teams, currentTeamIndex, currentRound, currentScreen, gameId)`.
  - Elle est mêlée aux mutations.
- **`FiestaState.turn` est une `Map<String, dynamic>` à 6 clés** (`turn_effects.dart:9-25`) :
  - les valeurs sont encodées de deux façons (`int`, `String`, plus `'armed'`/`'spent'`) ;
  - chaque lecteur refait sa garde de type (`_turnCounters`, `_turnString`, `_doublePoints`) ;
  - chaque écrivain refait `{...fiesta.turn, k: v}` ou `Map.of(..)..remove`.
  - **Bombe concrète :** la fin de manche (`:1136`) garde toute la map **sauf** `kSecondExpiredWordKey`, retirée à la main. La prochaine clé « vit le temps d'un écran » sera oubliée là.
  - Il n'existe aucun endroit unique qui dise quelles clés survivent à la fin de manche et lesquelles meurent à la fin du tour.
- **Duplication ×2 / « deux mots » :**
  - `doublePointsLeft` (`:1401`) et `twoWordsLeft` (`:1459`) sont identiques à l'id près ;
  - `doublePointsCapped` et `twoWordsCapped` (`:1414`, `:1471`) sont symétriques ;
  - `isXArmed` et `isXOn` sont dupliqués ;
  - les deux blocs de dépense de `startTurnTimer` (`:601`, `:614`) sont identiques ;
  - les trois `*Allowance` de `turn_effects.dart:28-42` font le même `fold` ;
  - `_doublePoints` duplique `_turnString`.
- **Code judo (comportement identique, JSON identique, donc aucun impact règle 7) :**
  1. `FiestaTurn` typé (`freePassesUsed`, `blockedPlayerId`, `Map<String, ChargeState> charges` indexé par catalogId, `secondWord`, `secondExpiredWord`). Il a un `toJson` qui **réécrit les mêmes clés** et des méthodes `afterRoundEnd()` / `afterTurn()`. C'est lui qui décide ce qui survit, et la clé oubliée devient impossible.
  2. Une table `kChargeBonuses = {'double_points': kDoublePointsKey, 'two_words': kTwoWordsKey}`. On en tire `chargesLeft(id)`, `isArmed(id)`, `isOn(id)`, `capped(id)` et `setArmed(id, on)`, et la dépense de `startTurnTimer` devient une boucle. Le provider perd environ 70 lignes, et une 3ᵉ charge future coûtera une ligne.
  3. Extraire le modèle de lecture dans `FiestaView(game, teams, settings)` (fichier `lib/models/fiesta/fiesta_view.dart`, pur et testable sans provider). Le provider ne garde que les mutations. Gain ≈400 lignes, et le provider repasse sous 1 700.
- **Pas requis avant la release :** le code n'est pas persisté, et la refonte typée peut garder les mêmes clés.

---

## MINOR

- **m1 — Plafond Q8 et incompatibilités Q14 non tenus à la jointure de la continuation.**
  - Pendant la continuation coexistent `fiesta.turn` de N (×2 ou « deux mots » `spent`, passes gratuites) et l'ensemble de modificateurs de N+1. On peut donc avoir « deux mots » ON avec `no_pass` tiré en N+1 (paire interdite), et jusqu'à 4 modificateurs en jeu.
  - Même cause : `_useful` et `canAdd` (`offers.dart:175,246,276`) ne regardent que `roundDraw + choices/gifts`. Ils ignorent les instances de portée tour **restantes**. Exemple : un blocage de N+1 non joué avant la fin de N+1 survit, et un second `block_guesser` peut être proposé contre la même équipe.
  - Fix : passer `fiesta.active` filtré à `taken`.
- **m2 — Le compteur de passes gratuites de N est hérité par les `free_pass` de N+1 pendant la continuation.** Résidu déjà au journal (2-8). C'est la même jointure que m1 et M3, donc ce sera à traiter avec M3.
- **m3 — La révélation de `minus_10s` est sautée si le tour de fin de manche avait des mots invalidés.**
  - Dans ce cas `pendingBonusTurnId` est nul et l'entrée de continuation n'est pas `isBonusContinuation`.
  - `firstFullTurn` (`game_provider.dart:1534`) devient donc faux au premier vrai tour. Le malus s'applique, mais n'est jamais révélé.
  - Fix : dériver « premier tour plein » d'autre chose que `isBonusContinuation`, ou du drapeau de M3.
- **m4 — Analytics, compteur faux en silence.**
  - `onWordInvalidated` et `onWordValidatedAsGuessed` étiquettent avec `_lastModifiers` (`analytics_service.dart:229,250`), un état **mémoire**.
  - Si l'app est tuée pendant la vérification d'une partie Fiesta, ces événements partent **sans clé `modifiers`**, c'est-à-dire avec la forme « Classique » selon la doc de `WordEvent`.
  - Fix : le provider passe les modificateurs (dérivés de l'état persisté) à ces deux appels, comme pour `onWordShown`.
  - À documenter aussi dans `ANALYTICS.md` : le tag veut dire « actif pour l'équipe ». En continuation, il inclut `minus_10s` de N+1, qui ne s'y applique pas.
- **m5 — Le blob Classique `guessItAll_gameState` n'est pas octet pour octet celui du store.**
  - `turnAllottedSeconds` y est écrit (`game_provider.dart:653`).
  - C'est additif : l'ancien lecteur l'ignore, et l'absence est tolérée. C'est voulu (correctif du temps par mot, journal « à valider »), et ce n'est pas un BLOCKER.
  - C'est le **seul** delta Classique du blob. Les analytics Classique et Firestore, eux, sont identiques (`fiesta_analytics_test:120`).
  - Détail : la lecture `as int?` lève sur un mauvais type, comme pour les champs voisins.
- **m6 — `ModifierRecapLine` archive des chaînes françaises déjà formées** (`game_result.dart:57`) dans `guessItAll_gameHistory`.
  - L'i18n est prévue (epic-4) : les récaps archivés resteront en français pour toujours.
  - Format à trancher **avant la release** : il sera gelé. L'alternative est d'archiver les données structurées (catalogId, teamId, manche, secondes) et de formater à l'affichage.
- **m7 — Recap et transition : deux dérivations qui doivent coïncider.**
  - La transition calcule rattrapage et coup de pouce sur `t.score`. Le récap (`modifier_recap.dart:58,106`) les recalcule sur `scoreByRound.take(round)`.
  - Ils coïncident **parce que** les points de continuation tombent dans N+1. Si on change où ils tombent, le récap diverge sans bruit.
  - Option : journaliser les cadeaux comme `offerChoices` (`chooserId: 'app'`).
- **m8 — En continuation, on peut armer ×2 ou « deux mots » avec les charges de N+1, même sur une continuation de 0 s.** C'est testé comme voulu (`fiesta_double_points_test:139`). Question de design : masquer les interrupteurs quand `turnBonusTime != null` ?
- **m9 — `turn` et `catchUpDue` sont toujours sérialisés, même vides** (`fiesta_state.dart:68-69`), alors que `chargesUsed` et `offerChoices` sont omis quand ils sont vides. C'est sans danger (le blob n'est pas publié), mais à homogénéiser avant le gel.
- **m10 — Tests : échafaudage dupliqué.**
  - `givenReadyProvider` existe en 7 copies, `playTurn` / `playEmptyTurn` / `finishRoundWithCarryOver` en 5 variantes, dans `test/providers/fiesta_*`.
  - À extraire dans `test/helpers/fiesta_game.dart`.
- **m11 — Code mort ou presque, déjà présent :** la branche `nextRoundNumber > 3` de `nextRound` est inatteignable, car `validateWords` envoie directement aux résultats en M3. Je la signale, je ne demande pas de la retirer.

---

## Persistance (règle 7) — inventaire complet

| Où | Clé ajoutée | Optionnelle / omise si vide | Lecture tolérante | Classique |
|---|---|---|---|---|
| `GameState` (`guessItAll_gameState`) | `fiesta` | oui (omise si nulle) | oui (`is Map` → `tryFromJson`, sinon Classique) | absente |
| `GameState` | `turnAllottedSeconds` | omise si nulle | `as int?`, comme les champs voisins | **écrite** (m5) |
| `fiesta` | `rules`, `active` | requises (blob neuf) | oui (règles illisibles → Classique ; instance illisible ignorée seule) | — |
| `fiesta` | `turn`, `catchUpDue` | **toujours écrites** (m9) | oui | — |
| `fiesta` | `chargesUsed`, `offerChoices` | omises si vides | oui (entrée par entrée) | — |
| `fiesta.turn` | `freePassesUsed`, `blockedPlayerId`, `doublePoints`, `twoWords`, `secondWord`, `secondExpiredWord` | absentes = valeur initiale | gardes `is int` / `is String` | — |
| `preValidationSnapshot.game` | idem, via `GameState.toJson` | — | — | — |
| `GameAnalytics` (local + Firestore) | `gameMode`, `fiestaRules` | omises si nulles | oui | absentes (test :120) |
| `WordEvent` | `modifiers` | omise si nulle | `whereType<String>` | absente |
| `GameResult` (`guessItAll_gameHistory`) | `mode`, `modifierRecap` | omises si nulles | oui | absentes |
| `guessItAll_fiestaEnsembles` (nouvelle) | blob entier | — | **versionné** `wrapWithSchema`, quarantaine, entrées illisibles réécrites telles quelles | — |

- Aucun changement de forme d'une clé `guessItAll_*` existante : il n'y a que des ajouts optionnels.
- `kCurrentSchemaVersion` est inchangé.
- **Pas de BLOCKER.**

## Garanties cross-story vérifiées, qui tiennent

- **nextRound :**
  - La garde d'écran (2-5) et la garde de file (2-10) sont toutes deux dans le provider.
  - Le tirage, les cadeaux et les choix sont **recalculés** à partir de l'état d'avant `nextRound`, puis posés en un seul `copyWith`.
  - Retour arrière depuis l'avant-tour de N+1 : l'ancien snapshot remplace `fiesta` entièrement, donc rien n'est appliqué deux fois.
  - App tuée sur la transition : tout est recalculé, et les choix déjà faits sont relus (`pick_three:118`).
- **Rattrapage (2-6) :**
  - Posé au `nextRound`, consommé une seule fois au premier tour non-continuation (`turnBonusTime == null` lu **avant** l'effacement).
  - Remplacé en bloc à la manche suivante.
  - Restauré par le retour arrière.
- **×2 (2-9) :**
  - La dépense a lieu dans `startTurnTimer` seulement.
  - Le retour arrière ne rend rien et ne redépense rien (snapshot pris après la dépense).
  - La continuation garde le ×2 sans redépenser.
  - `score == Σ scoreByRound` sur tous les chemins : ×2, continuation, undo, deux mots.
- **Deux mots (2-11) :**
  - `_shownAt` par mot : en Classique, le comportement reste équivalent, car chaque événement porte sur le dernier mot affiché.
  - La carte B est tirée aussi en continuation.
  - Les deux mots expirés sont gérés.
  - La fin de manche n'est possible qu'avec une seule carte.
- **Tags analytics :** ×2 n'est étiqueté qu'une fois dépensé. Les instances choisies et données sont étiquetées via `active`. Un mutant a été tué.
- **Plateformes (règle 8) :** aucun `dart:io` ni `Platform.*` dans le code Fiesta.

## Complexité — over-engineering dont la racine est la spec

- **Tout recalculer depuis la graine** (tirage, offres, cadeaux, récap) est le bon choix pour l'undo et le kill. Il a deux coûts :
  - la dérivation double de m7 ;
  - le résidu « une mise à jour entre la transition et Manche suivante change le tirage ».
  - Acceptable, à documenter.
- **La table de force et la descente d'un cran** sont simples et pures : rien à redire.
- **Le seul vrai sur-coût structurel est la jointure « un tour = fin de manche + continuation » posée sur un modèle où la continuation vit déjà en N+1.** Elle produit M3, m1, m2, m3 et m8. Un drapeau `continuation` explicite dans `FiestaTurn` (M5-1) supprimerait toute cette famille de cas spéciaux. Aujourd'hui, ils sont rafistolés au cas par cas : `minus_10s` / `firstFullTurn`, `turnBonusTime` lu avant effacement, `kSecondExpiredWordKey` retiré à la main.

## Tests

- **Valeur globale bonne :**
  - Les tests vont de bout en bout au niveau du provider, avec kill et undo à chaque story.
  - Le blob du store est relu (analytics, historique).
  - La parité Classique est testée par story.
- **Redondance :** l'échafaudage (m10), pas les assertions.
- **Invariants non figés :**
  - double validation (M4) ;
  - défaut et éditeur de `block_guesser` (M2) ;
  - `carryOver` (M1) ;
  - plafond Q8 pendant la continuation (m1) ;
  - événements de vérification après un kill en Fiesta (m4).
- **Un test fige un comportement contestable :** `fiesta_pick_three_test.dart:151` (M3).

---

## Refactors / corrections à faire avant la release

1. **M1** — retirer l'interrupteur `carryOver` de l'UI (ou le brancher).
2. **M2** — `block_guesser` : défaut `offer` dès M2, éditeur et validation limités à « Proposé ».
3. **M4** — garde d'écran sur `validateWords` et `savePreValidationState`, plus un test.
4. **M3** — décision Florent. Si on corrige : drapeau `continuation` dans `fiesta.turn`, et les instances de tour de N+1 survivent à la continuation.
5. **Formats gelés à la release, à trancher maintenant :**
   - m6 : récap en chaînes FR ou structuré ;
   - m9 : `turn` et `catchUpDue` omis quand vides.

## Peut attendre

- **M5 :**
  - `FiestaTurn` typé (mêmes clés JSON) ;
  - table `kChargeBonuses` ;
  - extraction de `FiestaView` (≈−400 lignes sur le provider).
- m1, m2, m3 : à traiter ensemble avec M3, ou après.
- m4 : modificateurs passés explicitement aux événements de vérification.
- m7 : journaliser les cadeaux.
- m8 : masquer les interrupteurs en continuation.
- m10 : helpers de test communs.
- m11 : branche morte de `nextRound`.
