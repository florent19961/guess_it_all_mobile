# Audit de code — Guess It All

## Verdict en une page

Le jeu tient debout et le soin se voit : recyclage des mots passés, undo de validation, report du temps entre manches, sync Firestore idempotente par `doc(gameId).set(...)` (firebase_sync_service.dart:153) — ce dernier point, le plus difficile de la zone cloud, est bien fait. La fragilité n'est pas répartie : elle est concentrée sur **trois racines**. (1) **Le modèle du temps est éclaté en trois représentations redondantes** — `_timeRemaining` local du TurnScreen (turn_screen.dart:20), `game.timeRemaining` poussé 10×/s (game_provider.dart:701), et `turnEndTimestamp` en horloge murale (game_provider.dart:521) — dont aucune n'est jamais gelée : la pause est un booléen de widget (turn_screen.dart:146) pendant que la deadline continue de courir, donc ouvrir un dialogue, prendre un appel ou verrouiller l'écran **vole réellement du temps de tour, jusqu'à le ramener à zéro**. (2) **Le schéma persisté n'a aucun numéro de version** sur les 9 clés `guessItAll_*`, et un blob illisible n'est jamais mis en quarantaine (storage_service.dart:76, game_analytics.dart:264, word_event.dart:104) — sur une app à mise à jour forcée par `upgrader`, la prochaine évolution de schéma est un pari non couvert, et `word_history_service.dart:143` va plus loin en **effaçant** l'historique accumulé sur une seule lecture ratée. (3) **Un seul provider de 1280 lignes** où `validateWords` fait 167 lignes (game_provider.dart:711) et où rien n'est atteignable isolément : aucune règle de score n'est testable sans instancier SharedPreferences, AnalyticsService et UserService.

À côté de ça, un **blocker franc et indépendant** : `main()` attend la vidange complète de la queue Firestore *avant* `runApp()` (main.dart:39 → firebase_sync_service.dart:99 → l.153), sans timeout — sur un Wi-Fi captif, l'app ne démarre jamais. C'est LA chose à corriger en premier : trois lignes, aucun arbitrage produit, et le mode de défaillance est « pas d'app ».

Le reste est du coût de maintenance, réel mais non urgent : ~341 lignes de dialogues copiés à l'octet près sur 4 écrans, un `stats_screen.dart` de 972 lignes dont plus du tiers est du rendu dupliqué, un design system contourné (7 usages d'`AppModal` contre 15 dialogues manuels), et des `CLAUDE.md` de zone qui décrivent une palette qui n'existe nulle part — ce sont pourtant les fichiers qu'un agent lit en premier. Enfin, l'absence de test n'est pas le problème en soi : le problème est que **la structure actuelle rend intestable exactement ce qui compte** (score, rotation, temps). C'est ce qui doit changer avant le mode Fiesta, pas après.

---

## Findings bloquants et majeurs

### [blocker] `main()` attend l'upload Firestore avant `runApp()` : l'app peut ne jamais démarrer

- **Où** : `lib/main.dart:39`, `lib/services/firebase_sync_service.dart:99`, `lib/services/firebase_sync_service.dart:153`
- **Le problème** : `main()` fait `await FirebaseSyncService().initialize()` (main.dart:39) **avant** `runApp()` (main.dart:80). `initialize()` termine par `await syncPendingGames()` si `_connectivity.isConnected` (l.98-99), qui boucle en séquentiel `await syncGame(gameId)` (l.196-203) jusqu'à `await ...doc(gameId).set(data)` (l.153) — dont la Future ne se résout qu'à l'ACK serveur, sans aucun `.timeout()`. Or `ConnectivityService` ne teste que le **type d'interface** (connectivity_service.dart:51-56) : sur un Wi-Fi de portail captif, `isConnected == true`. Précondition : queue `guessItAll_pending_sync` non vide, c'est-à-dire dès qu'une partie a été jouée hors ligne. Résultat : `runApp()` jamais atteint, splash native figée à vie. Le `try/catch` de main.dart:38-42 attrape des erreurs, pas un blocage. Cas dégradé garanti même en ligne : N uploads séquentiels avant le premier frame.
- **Le code** :
```dart
// firebase_sync_service.dart:97-100
    // Synchronisation initiale si online
    if (_connectivity.isConnected) {
      await syncPendingGames();
    }
```
- **Correction proposée** (S) : lancer `initialize()` en fire-and-forget **après** `runApp()`, et borner chaque écriture : `.set(data).timeout(const Duration(seconds: 10))` — le `catch` l.159 laisse déjà la partie dans la queue, ce qui est exactement la sémantique voulue. Un timeout sur la boucle ne suffit pas : il faut borner le `set()` individuel.

### [blocker] La pause ne gèle que l'affichage : l'horloge qui fait autorité continue de tourner pendant les dialogues

- **Où** : `lib/screens/turn_screen.dart:146`, `lib/providers/game_provider.dart:947`
- **Le problème** : `_isPaused` est un champ de `State` : il fait `return` au tick (turn_screen.dart:34) mais n'écrit **rien** dans `game.turnEndTimestamp`, seule source de vérité. Quand le joueur confirme le dialogue « Accueil », `suspendGame()` recalcule `pausedTime = ceil((turnEndTimestamp - now)/1000).clamp(0, 999)` (game_provider.dart:947-949) : **tout le temps passé dans le dialogue est décompté**. Au-delà du temps restant, clamp → 0, `resumeGame()` pose `turnEndTimestamp = now + 0` (l.966-972), et le premier tick au retour voit `remainingMs <= 0` et appelle `endTurn()` — tour terminé instantanément. En deçà, le vol est partiel et silencieux. `pausedTimeRemaining: 0` est **persisté** (l.951-960), donc la perte survit à un kill. Asymétrie probante : le chemin « Annuler » passe par `_togglePause` (turn_screen.dart:62-69) qui, lui, reconstruit correctement `turnEndTimestamp`.
- **Le code** :
```dart
// turn_screen.dart:146-151
    if (!_isPaused) {
      setState(() { _pausedTimeRemaining = _timeRemaining; _isPaused = true; });
    }
```
- **Correction proposée** (M, ~1-2 h) : déplacer la pause dans le provider — `pauseTurn()` écrit `pausedTimeRemaining` et met `turnEndTimestamp = null` ; `resumeTurn()` le recalcule. Le widget ne garde qu'un booléen d'affichage. `suspendGame` (l.947) tombera alors dans sa branche `: _game.timeRemaining` déjà existante et correcte. **Pré-requis du major « cycle de vie » ci-dessous.**

### [major] Aucune gestion du cycle de vie : revenir dans l'app après l'avoir quittée en plein tour termine le tour

- **Où** : `lib/providers/game_provider.dart:521`, `lib/screens/turn_screen.dart:44`
- **Le problème** : `grep AppLifecycleState|WidgetsBindingObserver|didChangeAppLifecycleState|PopScope` sur `lib/` → **zéro occurrence**. `turnEndTimestamp` est une deadline en horloge murale : appel entrant, notification plein écran, verrouillage ou back Android → au retour, le premier tick appelle `endTurn()`, mots restants perdus, mot affiché parti en `expiredWord`. Le trou est plus large qu'une interruption : `startTurnTimer` persiste `currentScreen: 'turn'` + `turnEndTimestamp` (l.518-531) et `_loadFromStorage` restaure `currentScreen` tel quel (l.83) — après un **kill de process** en plein tour, l'app relance directement sur TurnScreen avec un timestamp déjà expiré. Aucun wakelock au pubspec, donc l'auto-lock n'est pas exclu non plus.
- **Le code** :
```dart
// game_provider.dart:519-521
    _game = _game.copyWith(
      currentScreen: AppConstants.screenTurn,
      turnStartTimestamp: now,
      turnEndTimestamp: now + durationMs,
```
- **Correction proposée** (M, mutualisé avec le blocker précédent) : `WidgetsBindingObserver` sur `_TurnScreenState` — sur `paused`/`inactive`, appeler le `pauseTurn()` du provider ; sur `resumed`, **ne pas** reprendre automatiquement mais rouvrir le dialogue de pause existant. Couvre du même geste l'appel entrant, le back Android et la reprise après kill. `suspendGame`/`resumeGame` (l.942-977) font déjà le calcul : rien à inventer, juste à brancher.

### [major] `markWordAsGuessed` bascule en vérification sans purger la deadline : le temps bonus gagné est détruit

- **Où** : `lib/providers/game_provider.dart:596`
- **Le problème** : c'est le **seul** des deux chemins vers `screenVerification` qui laisse la deadline vivante — `endTurn()` pose bien `clearTurnStartTimestamp/clearTurnEndTimestamp` (l.693-694), cette branche non. Le `HomeButton` est monté sur l'écran de vérification (verification_screen.dart:230) et `screenVerification` est dans `gameScreens` (home_button.dart:42) : au bout de quelques secondes de vérification — le cas normal — `suspendGame` calcule `pausedTime` sur une deadline dépassée → 0, écrase `timeRemaining` (l.956), et `validateWords` lit `turnBonusTime: _game.timeRemaining = 0` (l.843). Les secondes que l'équipe venait de gagner en vidant la pile disparaissent, et la manche suivante démarre sur 0 s de report.
- **Le code** :
```dart
// game_provider.dart:591-597
        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          ...
          currentScreen: AppConstants.screenVerification,
        );
```
- **Correction proposée** (S) : ajouter `clearTurnStartTimestamp: true, clearTurnEndTimestamp: true` dans cette branche. Plus robuste : faire de `endTurn()` le seul chemin vers `screenVerification`, avec un drapeau « manche vidée ».

### [major] Chaque passe ré-ancre la deadline sur une seconde arrondie AU-DESSUS — à pénalité 0, le chrono se gèle

- **Où** : `lib/providers/game_provider.dart:627`
- **Le problème** : la nouvelle deadline vaut `now + (ceil(r/1000) - p)·1000`, soit un gain de 0 à 999 ms **à chaque passe**. `AppConstants.minPassPenalty = 0` (constants.dart:18) est exposé au slider (settings_screen.dart:461-466) et la garde l.630 devient inopérante : chaque tap repositionne la deadline à un multiple exact de seconde depuis maintenant, donc deux taps espacés de moins d'une seconde **restituent intégralement le temps écoulé**. Le bouton reste actif tant qu'un autre mot existe (turn_screen.dart:336, les passés étant recyclés l.647-649) et l'appel n'a aucun debounce (turn_screen.dart:449-456). À pénalité 0, enchaîner les passes est le jeu normal, pas une triche : le tour peut ne jamais se terminer. À la pénalité par défaut de 5 s, l'effet retombe à un biais de +0,5 s en moyenne par passe.
- **Le code** :
```dart
// game_provider.dart:626-637
    final currentRemaining = ((turnEndTimestamp - now) / 1000).ceil().clamp(0, 999);
    ...
    final newRemainingSeconds = currentRemaining - passPenalty;
    final newEndTimestamp = now + (newRemainingSeconds * 1000);
```
- **Correction proposée** (S) : travailler en millisecondes sans arrondi — `newEndTimestamp = turnEndTimestamp - passPenalty * 1000`, en gardant `if (turnEndTimestamp - now < passPenalty * 1000) return;`. L'arrondi ne doit servir qu'à l'**affichage**.

### [major] Zéro numéro de schéma sur les données persistées, et un blob illisible est indestructible

- **Où** : `lib/services/storage_service.dart:76`, `lib/models/game_analytics.dart:264`, `lib/models/word_event.dart:104`, `lib/models/game_state.dart:42`
- **Le problème** : aucune des 9 clés `guessItAll_*` ne porte de version, alors que `CLAUDE.md:100` exige explicitement une « migration explicite ». Les lectures mélangent du parsing défensif (`GameState.fromJson`, l.232-263) et des casts nus : `HistoryEntry.fromJson` (game_state.dart:42-49), `GameAnalytics.fromJson` (game_analytics.dart:264-291), et surtout `WordEventType.values.firstWhere(...)` **sans `orElse`** (word_event.dart:104) — ajouter un seul type d'événement rend illisibles toutes les parties déjà écrites. Le pire est la non-réparabilité : l'erreur est avalée (analytics_service.dart:261-263 ; game_provider.dart:89-91 fait un `debugPrint` sans jamais appeler `clearGameState()`), le blob toxique reste en base et re-échoue à chaque lancement. Côté analytics c'est structurel : `loadAllGames()` saute la partie illisible (l.275), donc `pruneOldGames()` ne peut jamais la mettre dans `toDelete` (l.315) — **clé + entrée d'index à vie, et la rétention de 50 ne borne plus rien**. Aucun chemin ne le déclenche aujourd'hui (writer et reader sont symétriques) : c'est un défaut latent, mais `upgrader` force la mise à jour sur tout le parc et le projet a **déjà** fait évoluer ce schéma en prod (commit `39a50ed`, ajout d'`isBonusContinuation`) — il ne s'en est sorti que parce que le défaut `as bool? ?? false` était là.
- **Le code** :
```dart
// word_event.dart:104-106 — aucun orElse
    eventType: WordEventType.values.firstWhere(
      (e) => e.name == json['eventType'],
    ),
```
- **Correction proposée** (M) : (1) écrire `'schemaVersion': 1` dans chaque `toJson()` et rejeter proprement une version inconnue à la lecture ; (2) rendre la lecture **auto-réparatrice** — `clearGameState()` avant de retourner `null`, et suppression de la clé **et** de l'entrée d'index côté analytics ; (3) `orElse` sur word_event.dart:104 ; (4) défauts sur tous les champs de `HistoryEntry`/`Player`/`Team` ; (5) sortir `notifyListeners()` du `try` de `_loadFromStorage` (bloc `finally`).

### [major] Une seule lecture ratée de l'historique des mots suffit à l'EFFACER intégralement

- **Où** : `lib/services/word_history_service.dart:143`
- **Le problème** : `_loadHistory()` confond « clé absente » (l.137-139, `{}` légitime) et « clé illisible » (l.143-146, `{}` aussi). `initialize()` pose alors `_historyCache = {}` **et** `_isInitialized = true` : le service se déclare sain avec un cache vide — et il ne peut jamais échouer, puisque l'exception est avalée en interne. À la fin de la partie suivante, `incrementWords` écrit `jsonEncode(_historyCache)` par-dessus (l.153) : les ~40 mots de la partie **remplacent** toutes les entrées accumulées. Perte irréversible, invisible (un `print` en release, zéro crash reporting au pubspec), symptôme visible des semaines plus tard.
- **Le code** :
```dart
// word_history_service.dart:143-146
    } catch (e) {
      print('[WordHistory] Error loading history: $e');
      return {};
    }
```
- **Correction proposée** (S) : lever un drapeau `_loadFailed = true` sur exception de décodage, et interdire à `_saveHistory()` d'écraser la clé tant qu'il est levé (ou renommer la clé fautive en `..._corrupt` avant de repartir de zéro). **Premier test du dépôt idéal** : `SharedPreferences.setMockInitialValues({'guessItAll_word_history': '{invalide'})` suffit, sans plugin natif.

### [major] Le tracking analytics n'est jamais réhydraté — et c'est lui qui incrémente l'historique des mots

- **Où** : `lib/providers/game_provider.dart:83`, `lib/services/analytics_service.dart:29`, `lib/services/analytics_service.dart:341`
- **Le problème** : `_game` est sauvegardé à chaque tap et rechargé au boot ; `_currentGame` n'a **aucun** équivalent (recensement des écritures : analytics_service.dart:60, 81, 97, 141/176/196/215 — aucune lecture depuis le stockage). Après un kill, la partie reprend mais `isTracking` est faux : `_trackWordShown` sort (game_provider.dart:537), et `endGame()` retourne à l.78 — or c'est **dans** `endGame` que vit `WordHistoryService().incrementWords()` (l.85-90). Comme la génération priorise les mots jamais vus (word_categories/utils.dart:56-57, 64, 150), **les mêmes mots peuvent ressortir à la partie suivante** : c'est un impact de jeu visible, pas seulement une perte de télémétrie. Le filet censé rattraper ça n'en est pas un : `finalizeOrphanedGames()` (l.330-365) *clôture* au lieu de récupérer, et n'incrémente pas non plus l'historique. Aucun chemin n'incrémente l'historique d'une partie ayant traversé un redémarrage.
- **Le code** :
```dart
// analytics_service.dart:77-90
  Future<void> endGame() async {
    if (_currentGame == null) return;
    ...
    final playedWords = _currentGame!.wordMetadata.keys.toList();
    if (playedWords.isNotEmpty) {
      await WordHistoryService().incrementWords(playedWords);
    }
```
- **Correction proposée** (M) : (a) le plus simple et le plus utile — **sortir `incrementWords` de `endGame`** pour que l'historique ne dépende plus du tracking (l'incrémenter en fin de manche) ; (b) sauvegarder les analytics au rythme de `_saveGameState()` et rehydrater `_currentGame` au boot quand `_game.gameId` correspond à une partie locale sans `endedAt`, au lieu de la clôturer ; (c) dans `finalizeOrphanedGames`, incrémenter aussi l'historique après l.348.

### [major] L'ordre de jeu est matérialisé en 1000 cycles répétés — ~95 % du blob persisté est du remplissage

- **Où** : `lib/providers/game_provider.dart:476`, `lib/providers/game_provider.dart:488`
- **Le problème** : 4 000 + 20 000 entiers stockés (bornes constants.dart:11-13) là où 24 suffiraient. Ils sont (a) recopiés par `copyWith` à chaque mutation (game_state.dart:174-177), donc à chaque mot deviné et chaque passe ; (b) `jsonEncode`és intégralement sur l'isolate UI à chaque `_saveGameState` (storage_service.dart:70), appelé après **chaque** mutation (l.510, 531, 614, 669, 698, 876, 928, 960, 976, 1206, 1261). Le code sait déjà cycler par modulo (l.895) : la répétition est du travail pur perte, en plein tour chronométré.
- **Le code** :
```dart
// game_provider.dart:474-478
    // Créer un cycle (répéter 1000 fois)
    final List<int> teamPlayOrder = [];
    for (int i = 0; i < 1000; i++) {
      teamPlayOrder.addAll(shuffledTeamIndices);
    }
```
- **Correction proposée** (M) : ne stocker que l'ordre mélangé et indexer par `% length` aux points de lecture (l.881, l.895) — **rétro-compatible sans effort**, l'ancienne liste étant périodique de même période. ⚠️ Réécrire aussi la boucle de comptage l.886-890, qui indexe `teamPlayOrder[i]` jusqu'à `nextTurnIndex` et partirait en `RangeError` sur une liste courte : le nombre de passages se calcule directement (`nextTurnIndex ~/ numTeams`, +1 si la position ≤ `nextTurnIndex % numTeams`).

### [major] Tirer UN mot coûte un scan complet du corpus, et deux chemins l'appellent jusqu'à 100 fois de suite

- **Où** : `lib/utils/word_categories/utils.dart:80`, `lib/screens/words_screen.dart:242`, `lib/screens/players_screen.dart:280`
- **Le problème** : `generateWordsFromCategoriesAsync(cats, count)` ne sait pas tirer moins que tout : quel que soit `count`, elle itère les 5 727 entrées des 12 catégories par défaut, en matérialise 3 648 (difficultés 1+2), refait un `Set` puis une `List` (l.96), puis `selectWordsByPriority` appelle `getSeenCount` sur **chacun** (deux allocations de String par mot, word_history_service.dart:128), les groupe, trie les clés et `shuffle()` un bucket de ~3 600 éléments pour n'en prendre qu'un. Le vrai amplificateur est `words_screen.dart:242-277` (`_fillAllEmptyWords`) : une passe par champ vide, chacune via `_generateUniqueWord` (l.98-121) qui boucle `while (attempts < 100)` sur cette même fonction — sur l'isolate UI, sans frame intercalée (les `await` sont des microtâches, le cache de `loadCategory` rendant les I/O gratuites dès le 2ᵉ appel). Le repli de `players_screen.dart:280-299` est un copier-coller du même code.
- **Le code** :
```dart
// utils.dart:96-99
  // Dédupliquer
  final uniqueWords = combinedWords.toSet().toList();

  return historyService.selectWordsByPriority(uniqueWords, count);
```
- **Correction proposée** (M) : exposer le pool — `buildWordPool(categories, levels)` construit **une fois** + `drawWords(pool, count)` pur. `players_screen.dart:96` et `:266-277` font déjà exactement ça avec `_wordPool`/`_availableWords` : `words_screen` doit tirer du même pool au lieu de le reconstruire, ce qui supprime aussi les deux boucles à 100 tentatives.

### [major] Le stockage des analytics est adossé à SharedPreferences, sur le même fichier que l'état de jeu

- **Où** : `lib/services/analytics_service.dart:233`, `lib/services/analytics_service.dart:310`
- **Le problème** : deux défauts de la même racine (des blobs de ~100 Ko × 50 dans un magasin clé-valeur). (a) SharedPreferences est **un** fichier, chargé intégralement en RAM Dart au premier `getInstance()` (`_preferenceCache`, shared_preferences_legacy.dart:108 alimenté par `getAll()` l.260) et réécrit en entier à chaque écriture (`commit()`, LegacySharedPreferencesPlugin.java:87). Or `guessItAll_gameState` vit dans le **même** fichier (constants.dart:27 via storage_service.dart:12-16) et est réécrit à chaque mot deviné (game_provider.dart:614) et chaque passe (l.669) : chaque tap réécrit le fichier complet, et chaque démarrage en paie le décodage + la résidence RAM. *(À ne pas confondre avec un jank : l'API plateforme tourne sur une background task queue, Messages.java:132 — le coût est disque et mémoire, pas thread UI.)* (b) `pruneOldGames()` désérialise les 50 parties **avant** de décider qu'il n'y a rien à faire — cas de 100 % des appels tant que la rétention n'est pas pleine.
- **Le code** :
```dart
// analytics_service.dart:308-312
  Future<void> pruneOldGames(int keepCount) async {
    try {
      final games = await loadAllGames();
      if (games.length <= keepCount) return;
```
- **Correction proposée** : (S) inverser `pruneOldGames` — `final index = await _loadIndex(); if (index.length <= keepCount) return;`, et stocker `startedAt` dans l'index plutôt que de désérialiser pour lire un champ. (L) sortir les blobs de SharedPreferences : un fichier JSON par partie via `path_provider`, l'index seul dans les prefs — la purge devient triviale et le couplage avec le chemin chaud du gameState disparaît.

### [major] Démarrer une partie depuis l'accueil efface les réglages persistants du joueur

- **Où** : `lib/screens/home_screen.dart:83` (aussi `:70` et `:134`)
- **Le problème** : les trois boutons appellent `clearLocalStorage()`, qui fait `_settings = GameSettings.initial(); await _saveSettings();` (game_provider.dart:1046-1047) — elle **écrase sur disque** la durée de tour, la pénalité, les catégories et les difficultés. La méthode prévue pour ça existe et est documentée « efface session ET state, garde settings » : `startNewGame()` (l.1000-1012), **appelée nulle part**. Deux signaux d'incohérence : `settings_screen.dart:326-357` offre déjà un bouton « Réinitialiser » dédié avec confirmation explicite pour la même méthode ; et le chemin « Rejouer » (`restartWithSamePlayers`, l.1015-1040) ne touche pas aux settings — deux entrées vers le même écran, deux comportements opposés.
- **Le code** :
```dart
// home_screen.dart:82-85
  onPressed: () async {
    await provider.clearLocalStorage();
    provider.goToScreen(AppConstants.screenSettings);
  }
```
- **Correction proposée** (S, + décision produit à acter) : remplacer les trois appels par `startNewGame()`, supprimer `resetGame()` (mort et marqué DEPRECATED l.1054), et garder `clearLocalStorage()` pour le seul bouton « Réinitialiser » de settings_screen:356. Le commentaire l.1042 annonce bien « Réinitialise TOUT : paramètres… » — donc l'arbitrage final t'appartient.

### [major] Le snapshot pré-validation est une deuxième sérialisation de `GameState`, écrite à la main

- **Où** : `lib/providers/game_provider.dart:1182` (et `:1210-1262`)
- **Le problème** : 80 lignes qui sérialisent/désérialisent 13 champs en parallèle de `toJson`/`fromJson`, relues en casts nus (l.1238-1250). Mode de défaillance silencieux : **tout champ ajouté à `GameState` est absent du snapshot sans que rien ne le signale** — `restoredValidatedWords` a déjà dû être ajouté aux deux endroits (l.1202 et 1257). La Map est imbriquée dans le blob persisté (game_state.dart:225), alourdit chaque sauvegarde de ~10-15 %, et n'est jamais effacée par `validateWords` (seulement par `restorePreValidationState` l.1256 et `goBackToTeams` l.1268) : elle survit dans chaque sauvegarde jusqu'à la fin de la partie.
- **Le code** :
```dart
// game_provider.dart:1182-1186
      preValidationSnapshot: {
        'currentRound': _game.currentRound,
        'currentTeamIndex': _game.currentTeamIndex,
        ...
        'history': _game.history.map((e) => e.toJson()).toList(),
```
- **Correction proposée** (L) : stocker `GameState? _preValidationState` (une copie via `copyWith()`) + la liste des scores. La restauration devient `_game = snapshot.copyWith(currentScreen: screenVerification, ...)`. Si l'undo n'a pas besoin de survivre à un kill — probable, c'est un geste immédiat — le sortir carrément de `GameState` et de la persistance : les 80 lignes et les casts nus disparaissent d'un coup. **C'est le point qui coûtera le plus cher au mode Fiesta** (chaque modificateur = un champ de plus à ne pas oublier ici).

### [major] 341 lignes de dialogues copiées à l'octet près entre 4 écrans

- **Où** : `lib/screens/game_screen.dart:462`, `lib/screens/turn_screen.dart:272`, `lib/screens/results_screen.dart:383`, `lib/screens/transition_screen.dart:278`
- **Le problème** : duplication **vérifiée par `diff`**, pas estimée. `_showTeamMembersDialog` : 48 lignes identiques × 4 (game:462-509, turn:272-319, results:383-430, transition:278-325). `_showBackToVerificationDialog` : 44 lignes identiques × 3 (game:281-324, results:79-122, transition:233-276). `_showGuessedWordsDialog` : 109 lignes × 2 (game:511-619, transition:327-435). S'y ajoute le quasi-doublon turn_screen:154-196 vs home_button.dart:47-88. Toute correction — le `dynamic team` non typé qui prive l'analyzer de tout filet, l'ajout d'un score, un changement de bordure — doit être répétée 4 fois, dans une base sans un seul test pour rattraper l'oubli, sur 4 écrans qui s'enchaînent dans la **même** partie.
- **Le code** :
```dart
// game_screen.dart:462 — identique octet pour octet dans 3 autres fichiers
  void _showTeamMembersDialog(BuildContext context, dynamic team, GameProvider provider, Color teamColor) {
```
- **Correction proposée** (M, ~2 h) : extraire dans `lib/widgets/dialogs/` — `showTeamMembersDialog(context, Team team, Color color)`, `showBackToVerificationDialog(context, provider)`, `showLastTurnWordsDialog(context, provider)`. Typer `team` en `Team` au passage. 2 à 4 appelants réels par helper : aucune abstraction spéculative.

### [major] `stats_screen.dart` : 4 builders quasi identiques, plus du tiers du fichier

- **Où** : `lib/screens/stats_screen.dart:194` (et `:339`, `:490`, `:634`)
- **Le problème** : `diff` vérifié — les blocs 194-279 et 634-719 sont identiques à l'octet, 339-425 et 490-576 aussi ; entre les deux paires, seuls diffèrent un nom de variable, un `widthFactor`, `width` 50 vs 45 et `fontSize` 18 vs 16. La boucle « trouver la couleur de l'équipe » est recopiée **5 fois** (l.203, 348, 499, 643, 803). `_buildTopPlayersWordsByRound` (l.582-585) est `_buildTopPlayersWords` (l.147) plus un `.where((e) => e.round == round)` ; idem `_buildPlayerRankingByRound` (l.431-435). Total : ~344 lignes de rendu dupliqué sur 972.
- **Le code** :
```dart
// stats_screen.dart:194-279 ≡ 634-719 (diff vide)
```
- **Correction proposée** (M, ~3 h) : un unique `_buildRankedBars({title, icon, rows})` + deux fonctions d'agrégation prenant `int? round` (null = partie entière), et un `provider.getTeamColorForPlayer(playerId)`. **Ces deux agrégations, une fois extraites, seraient les premières fonctions pures et testables du dépôt** (entrée = `game.history`).

### [major] Les `CLAUDE.md` de zone décrivent un design system qui n'existe pas

- **Où** : `lib/theme/CLAUDE.md:9` (et `lib/widgets/effects/CLAUDE.md:7`, `lib/services/CLAUDE.md:23`)
- **Le problème** : **aucune** des 5 lignes de palette (theme/CLAUDE.md:8-12) n'est vraie. Réel : `backgroundMain = 0xFF1E293B` (app_theme.dart:5, bleu ardoise — pas `#0A0A0A`), `primaryPink = 0xFFF19B9B` (l.9, saumon pâle — pas `#FF3B7F`), `secondaryCyan = 0xFF7DD3C0` (l.13, turquoise pastel — pas `#00E5FF`), 4 gris et non 5 (l.22-25), et `error = 0xFFE88B8B` (l.18) est **strictement égal** à `primaryPinkDark` (l.10) — donc pas « rouge ». `effects/CLAUDE.md:7` documente une classe `ShootingStarsBackground` qui n'existe pas (c'est `ShootingStars`, shooting_stars.dart:4). Ce sont exactement les fichiers qu'un agent lit **avant** de grepper : une palette 100 % inventée pilote directement des décisions de couleur et de contraste.
- **Le code** :
```markdown
### `AppColors`
- **Background** : noir `#0A0A0A`
- **Primary** : rose `#FF3B7F`
```
- **Correction proposée** (S) : réécrire `theme/CLAUDE.md` depuis `app_theme.dart` et y signaler explicitement que `error == primaryPinkDark` (à assumer ou à corriger). Corriger `ShootingStarsBackground` → `ShootingStars`. Corriger `services/CLAUDE.md:23` (`guessItAll_session` → `guessItAll_gameSession`) et y ajouter `guessItAll_advancedSettingsSeen` : le tableau doit compter 9 lignes, en 1:1 avec `grep -rn guessItAll_ lib/`.

---

## Findings mineurs

| Zone | Fichier:ligne | Axe | Problème | Effort |
|---|---|---|---|---|
| cœur | `lib/providers/game_provider.dart:843` | robustesse | Manche finie au buzzer → `turnBonusTime = 0` : décompte 3-2-1 pour un tour qui meurt au premier tick, mot d'ouverture brûlé en `expiredWord`, et `game_screen.dart:182` affiche « Temps bonus : 0s » là où `transition_screen.dart:149` filtre déjà les 0 | S |
| cœur / écrans | `lib/providers/game_provider.dart:701` + `lib/screens/turn_screen.dart:56` | efficacité | `updateTimeRemaining` pousse 10×/s un `copyWith` complet (~24 000 int recopiés) pour un champ qu'aucun widget ne lit. ⚠️ Ne pas le supprimer sec : `validateWords` l.788 et 843 en dépendent — ajouter la garde `if (remaining == _timeRemaining) return;` | S |
| cœur | `lib/providers/game_provider.dart:736` | robustesse | Revenir sur la validation puis revalider ré-émet les mêmes événements analytics (`addEvent` est un append pur, game_analytics.dart:156) — le jeu est bien rembobiné, les stats non | M |
| cœur | `lib/providers/game_provider.dart:711` | lisibilité | `validateWords` = 167 lignes / 6 responsabilités ; aucune règle de score atteignable sans instancier tout le provider | L |
| cœur | `lib/providers/game_provider.dart:1055` | simplicité | 6 méthodes de reset aux sémantiques recouvrantes, dont 3 sans aucun appelant (`resetGame`, `startNewGame`, `clearPlayersData`) + 3 getters morts | S |
| cœur | `lib/providers/game_provider.dart:788` | robustesse | `timeSpent = turnDuration - timeRemaining` même pour un segment bonus qui n'a jamais duré aussi longtemps : la somme des deux segments d'un tour dépasse la durée du tour (43 s pour 30 s) | S |
| cœur | `lib/providers/game_provider.dart:100` | simplicité | Joueurs/équipes persistés dans 2 clés concurrentes ; au chargement le `state` écrase la `session` (l.75-82), préséance implicite non documentée | M |
| services | `lib/services/word_history_service.dart:153` | efficacité | Historique sans plafond ni purge (contraste avec `defaultRetentionCount = 50`), grossi par les mots personnalisés, décodé avant `runApp()` (main.dart:52-57) | S |
| services | `lib/services/word_loader_service.dart:54` | réutilisabilité | Deux idiomes d'init paresseuse ; la garde `if (!loader.isInitialized)` est recopiée 5 fois dans `utils.dart` et `categories_screen.dart:34` utilise le getter brut qui throw | S |
| services | `lib/utils/word_categories/utils.dart:74` | réutilisabilité | 3 générateurs quasi identiques (l.74-96, 115-136, 159-190) ; et la branche `selectedCategories.isEmpty` **est atteignable** et ré-inclut silencieusement `metro_parisien` que le produit exclut | M |
| services | `lib/services/storage_service.dart:17` | robustesse | 20 `print` dans `lib/` et **zéro** crash reporting au pubspec : chaque `catch` avalé est invisible en production, sur une app à mise à jour forcée | S |
| services | `lib/services/word_loader_service.dart:139` | simplicité | API publique morte : `changeLocale`/`loadAllCategories`/`clearCache`, `WordHistoryService.getStats`/`clearHistory`, `UserService.clearCache`, `ConnectivityService.dispose`, `FirebaseSyncService.dispose` — plus une abstraction de locale pour une seule locale | S |
| services | `lib/utils/constants.dart:52` | robustesse | `defaultCategories` = 2ᵉ source de vérité des IDs, persistée et jamais confrontée à `categories.json` ; l'exclusion `metro_parisien` vit à 2 endroits (ici + `categories_screen.dart:20`) | M |
| analytics | `lib/services/analytics_service.dart:342` | robustesse | `finalizeOrphanedGames` fabrique `endedAt = DateTime.now()` : une partie de 40 min rouverte le lendemain remonte 43 200 s dans Firestore, et la partie est clôturée alors qu'elle est encore jouable | S |
| analytics | `lib/models/word_stats.dart:124` | robustesse | `expired`/`invalidated` produits et uploadés mais consommés par aucun calcul ; un mot validé a posteriori a `durationMs: null` → `?? 0` → il arrive **premier** dans un tri croissant | M |
| analytics | `lib/models/word_event.dart:84` | robustesse | `durationMs` sans clamp absorbe le temps de suspension ; `suspendGame`/`resumeGame` corrigent le chrono de jeu mais pas `_lastShownTimestamp` | S |
| analytics | `lib/services/firebase_sync_service.dart:159` | robustesse | Aucune borne de tentatives, aucun backoff, aucun dead-letter : une entrée est rejouée au boot et à chaque événement de connectivité (stream sans `distinct()`) | M |
| analytics | `lib/services/firebase_sync_service.dart:175` | robustesse | `_isSyncing` ne garde que `syncPendingGames` ; `syncGame` fire-and-forget (l.124) peut tourner en parallèle. Sans dégât (`set()` idempotent), mais `_removeFromPending` (l.226-231) est un read-modify-write non atomique | S |
| analytics | `lib/services/firebase_sync_service.dart:245` | simplicité | ~50 lignes d'API publique sans consommateur (`SyncResult`, `isSyncing`, `isInitialized`, `getPendingGameIds`, `forceSyncNow`, `dispose`) sur 249 | S |
| analytics | `lib/models/word_stats.dart:168` | lisibilité | `roundStats` commenté « 3 éléments (M1, M2, M3) » alors que la liste fait 0 à 3 ; effet déjà actif : `avgTotalTimeMs` divise par `roundStats.length` ≠ « moyenne par manche » | S |
| analytics | `docs/ANALYTICS.md:5` | lisibilité | Le doc annonce une « future integration cloud » alors que chaque partie est uploadée (mot par mot, `userId`, `deviceModel`) ; + signature `onWordShown` fausse, 2 services absents de l'arbre, `guessItAll_pending_sync` absente | S |
| écrans | `lib/screens/players_screen.dart:127` | robustesse | `setState` après `await` sans garde `mounted` ; l'`AppBackButton` (l.464) reste cliquable pendant le spinner | S |
| écrans | `lib/screens/verification_screen.dart:33` | robustesse | Suspendre pendant la vérification recoche **tous** les mots au retour (`_validatedWords` local jamais persisté) et rejoue le klaxon | S |
| écrans | `lib/screens/results_screen.dart:125` | lisibilité | `_getRank` retourne son propre index (paramètre inutilisé) ; les libellés « (ou ex æquo) » l.157/184 promettent un traitement que le podium ne fait pas — le rendu des égalités diverge de `transition_screen.dart:74-80` | S |
| écrans | `lib/screens/words_screen.dart:336` | efficacité | `_getOtherPlayersWords` recalculé 2× par ligne visible, à chaque frappe clavier, pour un résultat invariant par ligne | S |
| écrans | `lib/app.dart:37` | simplicité | `Consumer` au-dessus de `MaterialApp` → MaterialApp/Navigator/UpgradeAlert rebuildés à chaque `notifyListeners` ; et l'absence de pile de routes détruit le `State` de chaque écran à chaque aller-retour | S |
| widgets/utils | `lib/widgets/effects/shooting_stars.dart:92` | efficacité | Deux `CustomPaint` animés en continu sans `RepaintBoundary` sur 9 écrans/14, et géométrie constante re-tirée via `Random(seed)` à chaque frame | S |
| widgets/utils | `lib/widgets/effects/shooting_stars.dart:44` | lisibilité | Fond `#2B3848` hors palette : plus clair que `backgroundMain` (#1E293B) de la barre système, et changer `AppColors.backgroundMain` ne bouge rien sur 9 écrans | S |
| widgets/utils | `lib/widgets/common/app_button.dart:40` | simplicité | `disabled` et `onPressed: null` expriment la même chose mais seul `disabled` a un effet visuel → un bouton plein rose, animé à la pression, qui ne fait rien | S |
| widgets/utils | `lib/widgets/common/app_input.dart:126` | robustesse | `_controller.text` lu au build sans `addListener` : la croix d'effacement (activée **par défaut**, l.27) ne suit la saisie que si l'appelant rebuild lui-même | S |
| widgets/utils | `lib/widgets/common/back_button.dart:4` | lisibilité | `GameBackButton` (4 appelants) voisine `AppBackButton` (7 appelants), apparences différentes ; la doc de zone attribue à l'un le `disabled` de l'autre ; les 3 boutons renvoient un `Positioned` nu sans le documenter | S |
| widgets/utils | `lib/utils/constants.dart:12` | simplicité | 7 constantes sans appelant, dont `minPlayers = 4` alors que le minimum réel est `numberOfTeams * 2` (settings_screen.dart:85 et :102) | S |
| widgets/utils | `pubspec.yaml:63` | simplicité | `marques_annotated.json` (18,7 ko, schéma illisible par l'app, 427 mots vs 460) bundlé via une déclaration d'assets **au répertoire** | S |
| widgets/utils | `tools/convert_words_to_json.dart:46` | robustesse | Régénère les assets depuis `backup/` gitignoré : le rejouer **annule la déduplication** (~570 doublons réinjectés) ; sur un clone neuf il crashe (`listSync` l.58) | M |
| widgets/utils | `tools/deduplicate_all_json.py:106` | robustesse | Chemin absolu d'une autre machine, inexistant → le script affiche « Aucun doublon trouvé ! » en ne lisant rien ; écrit en place sans `--dry-run` ni backup | S |
| widgets/utils | `reorganize_words.py:47` | simplicité | 534 lignes + un README à la racine pour un outil dont le fichier d'entrée a disparu à la migration JSON ; `moved_count` structurellement 0 | S |
| widgets/utils | `resize_images.py:48` | robustesse | `img.resize(target_size)` sans préserver le ratio : une capture Android 1080×2400 sort étirée de ~2,6 % — et ce sont les fichiers déposés sur les stores | S |

### Nits

| Zone | Fichier:ligne | Axe | Problème | Effort |
|---|---|---|---|---|
| services | `lib/services/connectivity_service.dart:59` | efficacité | Émet sur chaque événement réseau au lieu des seules transitions (contrat de stream « échantillons » plutôt que « changements ») | S |
| services | `lib/services/connectivity_service.dart:63` | robustesse | `dispose()` ferme un `StreamController` `final` de singleton **et** remet `_isInitialized = false` — inerte (aucun appelant), à supprimer avec l'API morte | S |
| analytics | `lib/models/game_analytics.dart:156` | efficacité | `addEvent` recopie toute la liste + 17 champs → ~58 000 copies de références par partie ; gratuit à corriger, invisible aujourd'hui | S |
| écrans | `lib/screens/categories_screen.dart:64` | robustesse | État d'erreur sans `AppBackButton` dans une app sans pile de routes = cul-de-sac ; atteignable seulement avec un bundle corrompu | S |
| écrans | `lib/screens/players_screen.dart:89` | lisibilité | Deux `print()` de débogage dans le binaire publié (`avoid_print` est actif via `analysis_options.yaml:10`) | S |
| écrans | `lib/screens/players_screen.dart:23` | simplicité | `_errors` jamais écrite (retourne toujours `null`), `timerRefreshMs`/`countdownDuration` jamais lues, et `_timeRemaining = 30` en dur flashe une valeur fausse à chaque tour si `turnDuration ≠ 30` | S |
| widgets/utils | `lib/utils/word_categories/models.dart:39` | simplicité | `WordCategory.fromJson`/`toJson` et `WordWithDifficulty.toJson` morts, et ils documentent un format qui n'existe pas (le vrai est `{categoryId, words[]}`) | S |

---

## Lecture par axe

- **Efficacité** — Le gaspillage est structurel, pas diffus : ~95 % du blob persisté est du remplissage (24 000 int recopiés à chaque mutation, game_provider.dart:476), le tirage d'un mot scanne 5 727 entrées et peut être bouclé 100 fois (utils.dart:80 ← words_screen.dart:242), et `pruneOldGames` désérialise 50 parties pour comparer un entier (analytics_service.dart:310). Aucun jank n'est **démontré** — plusieurs claims de rebuild ont été réfutés (voir écartés) — mais quatre corrections tiennent chacune en quelques lignes.
- **Lisibilité** — Correcte en surface (français cohérent, fonctions courtes dans `widgets/common`), mais deux points durs : `validateWords` à 167 lignes (game_provider.dart:711) et `stats_screen.dart` à 972 lignes dont ~344 dupliquées. Le vrai problème est documentaire : `theme/CLAUDE.md:9` décrit une palette dont **0 valeur sur 5** est vraie, `services/CLAUDE.md:23` nomme mal une clé persistée, `docs/ANALYTICS.md:5` nie une synchronisation cloud livrée.
- **Simplicité** — Environ 500 lignes d'API publique et d'outillage sans aucun appelant : 6 méthodes de reset dont 3 mortes (game_provider.dart:1055), ~50 lignes dans `FirebaseSyncService`, 7 méthodes de services, 7 constantes, 3 membres de `models.dart`, plus 534 lignes de `reorganize_words.py` et un `convert_words_to_json.dart` dont la source d'entrée n'est plus versionnée. À l'inverse, la complexité **accidentelle** se concentre sur un point : 80 lignes de sérialisation manuelle en double de `toJson`/`fromJson` (game_provider.dart:1182).
- **Réutilisabilité** — C'est l'axe le plus chiffrable : **341 lignes de dialogues identiques à l'octet** sur 4 écrans, ~344 lignes de rendu dupliqué dans `stats_screen`, 3 générateurs de mots quasi identiques dans `utils.dart`, 5 recopies de la garde d'init paresseuse, 5 recopies de la boucle « couleur d'équipe ». Le design system existe mais est contourné : `AppModal` a 7 appelants contre 15 `showDialog` manuels (dont un dans `widgets/common/home_button.dart:47`), et `AppTextStyles.body/bodySmall/label` ont **zéro** appelant face à 106 `fontFamily: 'Poppins'` inline.
- **Robustesse** — L'axe le plus faible, et pour une raison identifiable : **rien n'est jamais gelé et rien n'est jamais versionné**. Zéro `WidgetsBindingObserver` dans tout `lib/`, une deadline en horloge murale comme seule autorité, zéro `schemaVersion` sur 9 clés persistées, zéro quarantaine d'un blob illisible, zéro crash reporting pour 20 `catch`/`print`. Les deux blockers et 6 des 15 majors sortent de ces deux absences.

---

## Ce qui a été écarté à la vérification

**Finding rejeté (1)**

- **« `endGame()` crédite l'historique de TOUS les mots même si la partie est abandonnée au premier mot »** (analytics_service.dart:87) — le fait de code est juste, le scénario est irréalisable. `startNewGame()` (game_provider.dart:1000), seul chemin qui appellerait `endGame()` sur une partie non finie, **n'a aucun appelant**. Le bouton « Nouvelle partie » passe par `clearLocalStorage()` (home_screen.dart:134) qui ne touche jamais aux analytics. Tous les appels atteignables à `endGame()` supposent une partie terminée, où `wordMetadata.keys` == mots réellement joués. *Résidu noté sans être facturé : ce couplage est correct par accident de flux et deviendrait faux le jour où une sortie de partie anticipée serait ajoutée — donc à re-vérifier avec Fiesta.*

**Mécanismes réfutés en cours de vérification** (à ne pas re-signaler)

- **Le `Consumer` racine ne rebuild PAS l'arbre complet.** `_buildCurrentScreen` renvoie des instances `const` (app.dart:58-86) : `Element.updateChild` court-circuite sur `child.widget == newWidget`. Le surcoût se limite à MaterialApp/Navigator/UpgradeAlert. Corollaire : « le tick provoque 20 rebuilds/s de l'écran » est faux (c'est 10, dus au `setState` local), et « supprimer `updateTimeRemaining` » **casserait** `validateWords` l.788 et l.843.
- **`ListView` isole déjà ses enfants** (`addRepaintBoundaries: true` par défaut) : les listes de catégories et de joueurs ne sont pas re-rastérisées par `ShootingStars`. Et l'effet n'est monté sur **aucun** des écrans chauds (ni turn, ni countdown, ni verification).
- **L'upload Firestore est idempotent au repos** : `doc(gameId).set(...)` (firebase_sync_service.dart:153) écrase le même document — pas de doublon possible, et la queue n'est purgée qu'après un `set()` réussi. Le double-upload concurrent coûte une écriture facturée, pas une corruption.
- **`convert_words_to_json.dart` ne perd pas 422 mots ajoutés** : les JSON sont un sous-ensemble **strict** du `backup/` (0 mot présent en JSON et absent du `.dart`, sur les 13 catégories). Le rejouer réinjecte ~570 doublons, c'est-à-dire annule la déduplication — dégât visible en diff et revertable, pas une perte.
- **`ConnectivityService` qui ré-émet ne gaspille pas de réseau** : queue vide → sortie immédiate ; queue pleine → réessayer *est* la sémantique offline-first voulue. Et `_isSyncing` couvre les rafales.
- **`FirebaseSyncService.dispose()` n'est pas un piège dormant** : `cancel()` (l.246) tue bien l'ancien abonnement. `getPendingCount()` **a** 3 appelants internes (l.177, 205, 238) et ne doit pas être supprimé.
- **`metro_parisien` commenté dans `constants.dart:52` n'est pas une divergence accidentelle** : c'est une décision produit répliquée dans `categories_screen.dart:20` (`_excludedFromSelectAll`). Le défaut est qu'elle vit à deux endroits, rien de plus.
- **Le tour bonus de 0 s n'est pas un tour volé** : le segment bonus est la **continuation** du même tour (`currentTurn` n'est pas incrémenté, l.811/858), donc 0 s de report est arithmétiquement juste. Le préjudice est cosmétique et statistique — d'où sa relégation en mineur.
- **Le pré-check « pas assez de mots » (settings_screen.dart:218-227) fonctionne** : un pool amputé rend un total plus petit, donc la partie ne démarre pas. Il ne dit simplement pas *pourquoi*.
- **`debugPrint` n'est pas retiré en release** (il throttle puis appelle `print`) : uniformiser dessus éteint 20 lints `avoid_print` et **ne change rien** à la visibilité en production. Le vrai sujet est l'absence de reporter d'erreurs.
- **`categories_screen` en état d'erreur est quasi inatteignable** en build publié (`assets/translations/` est déclaré au pubspec:62 et `categories.json` est valide, 13 catégories).

---

## Plan d'attaque proposé

### 1. Débloquer le démarrage — `runApp()` avant tout réseau ⏱ S · 🔴 blocker
**Ce qu'on gagne** : l'app démarre toujours. **Effort** : S (3 lignes — sortir `initialize()` de l'await, `.timeout()` sur `set()`). **Risque à ne pas le faire** : sur un Wi-Fi captif avec une queue non vide, l'app ne boote pas, et `upgrader` distribue cette version à tout le parc. Aucun arbitrage produit, aucune dépendance. **À faire aujourd'hui.**

### 2. Unifier le modèle du temps et brancher le cycle de vie ⏱ M · 🔴 **PRÉ-REQUIS FIESTA**
Chantier unique regroupant les 5 findings de la même racine : pause dans le provider (`pauseTurn`/`resumeTurn`, turn_screen.dart:146) → `WidgetsBindingObserver` (turn_screen.dart:44) → purge de la deadline dans `markWordAsGuessed` (game_provider.dart:596) → passe en millisecondes sans arrondi (l.627) → suppression de la 3ᵉ représentation du temps (`updateTimeRemaining`, l.701, **après** avoir dérivé `timeRemaining` de `turnEndTimestamp`).
**Ce qu'on gagne** : une seule autorité sur le temps, gelable, testable. **Effort** : M (~1 journée). **Risque à ne pas le faire** : deux blockers et deux majors restent atteignables **chaque soirée** — un appel entrant, un dialogue trop long, une pénalité de passe à 0. **Pourquoi c'est un pré-requis Fiesta** : les malus de temps, les tours bonus de rattrapage et les règles par manche sont tous des **mutations du temps de tour**. Empiler des modificateurs sur trois représentations désynchronisées qu'aucun chemin ne gèle, c'est garantir des bugs de temps combinatoires et non reproductibles.

### 3. Versionner et sécuriser le schéma persisté ⏱ M · 🔴 **PRÉ-REQUIS FIESTA**
`schemaVersion` sur les 9 clés `guessItAll_*` + rejet propre d'une version inconnue + **quarantaine** (`clearGameState()` avant `null`, suppression clé **et** index côté analytics) + `orElse` sur `word_event.dart:104` + défauts sur `HistoryEntry`/`Player`/`Team` + drapeau anti-écrasement sur `word_history_service.dart:143`.
**Ce qu'on gagne** : le droit de faire évoluer le schéma sans parier. **Effort** : M. **Risque à ne pas le faire** : `upgrader` force la montée de version sur des téléphones qui portent une partie en cours ; aujourd'hui un seul champ ajouté sans défaut rend une partie irrécupérable **et** l'échec est permanent, et une lecture ratée **efface** l'historique accumulé. **Pourquoi c'est un pré-requis Fiesta** : Fiesta ajoute par construction des champs à `GameState` (modificateurs actifs, joueurs bloqués, contraintes de manche) — c'est exactement l'événement contre lequel ce chantier protège. Le faire **après** la première release Fiesta, c'est le faire trop tard.

### 4. Rendre la machine à états testable : découper `validateWords` et tuer le snapshot manuel ⏱ L · 🔴 **PRÉ-REQUIS FIESTA**
Extraire la rotation (`_generatePlayOrder` l.469-499 + `_getNextPlayerWithRotation` l.879-902 — calcul pur, sans dépendance) ; découper `validateWords` (l.711-877) en `_partitionWords` / `_rebuildPool` / `_buildHistoryEntry`, laissant ~40 lignes d'orchestration ; remplacer le `preValidationSnapshot` (l.1182-1262) par un `GameState? _preValidationState`. En sortie : **les premiers tests unitaires du dépôt**, sur le score et la rotation, sans SharedPreferences ni Firebase.
**Ce qu'on gagne** : la règle de score devient vérifiable. **Effort** : L. **Risque à ne pas le faire** : chaque modificateur Fiesta touchera ces 167 lignes à l'aveugle, et **tout champ ajouté à `GameState` sera silencieusement absent du snapshot d'undo** — le mode de défaillance le plus insidieux du dépôt (déjà survenu avec `restoredValidatedWords`). **Pourquoi c'est un pré-requis Fiesta** : les modificateurs par manche et le tour bonus de rattrapage *sont* du scoring et de la machine à états. Sans point d'accroche testable, on ajoute des règles sur du code dont personne ne peut prouver le comportement actuel.

### 5. Alléger le persisté et sortir les analytics de SharedPreferences ⏱ M→L · 🟠 fortement recommandé avant Fiesta
Ordre de jeu en modulo au lieu de ×1000 (game_provider.dart:476, avec la réécriture de la boucle l.886-890) ; inversion de `pruneOldGames` (S, 2 lignes) ; puis blobs analytics en fichiers via `path_provider`. En bonus, le pool de mots partagé entre `words_screen` et `players_screen` (utils.dart:80).
**Ce qu'on gagne** : le blob persisté divisé par ~20, chaque tap qui ne réécrit plus des mégaoctets. **Effort** : M pour les deux premiers, L pour le déport de fichiers. **Risque à ne pas le faire** : ça ne casse rien aujourd'hui, mais ça **grossit silencieusement avec l'usage** — et Fiesta ajoutera des champs par-dessus un état déjà gonflé d'un facteur 1000, réécrit après chaque mutation. Les deux premiers items sont à faire avec le chantier 4 tant qu'on est dans le fichier.

### 6. Dédupliquer les écrans et remettre le design system en circuit ⏱ M · 🟢 dette pure, après Fiesta acceptable
3 helpers de dialogue dans `lib/widgets/dialogs/` (341 lignes récupérées), un builder de barre classée paramétré dans `stats_screen` (~170 lignes), les 15 `showDialog` manuels ramenés sur `AppModal` — en commençant par `home_button.dart:47` qui vit dans le même dossier. Plus la correction des trois `CLAUDE.md` (palette, classe, clés persistées) et du `clearLocalStorage()` de `home_screen.dart:83`.
**Ce qu'on gagne** : ~500 lignes en moins et des écrans qui ne peuvent plus diverger. **Effort** : M. **Risque à ne pas le faire** : chaque écran Fiesta ajoutera une 5ᵉ copie, et un agent qui lit `theme/CLAUDE.md` en premier codera contre une palette inventée. ⚠️ **Exception à sortir du lot et à traiter tôt** : la correction des `CLAUDE.md` est un S de 20 minutes qui conditionne la qualité de tout ce que les agents produiront sur Fiesta — à faire **avant** le chantier 2, pas après.