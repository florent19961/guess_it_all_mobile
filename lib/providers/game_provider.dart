import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/fiesta_state.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/turn_clock.dart';
import '../models/game_result.dart';
import '../models/play_rotation.dart';
import '../models/turn_resolution.dart';
import '../models/word_stats.dart';
import '../services/game_history_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../utils/word_categories/utils.dart' show lookupWordsMetadata;

class GameProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AnalyticsService _analytics = AnalyticsService();
  final UserService _userService = UserService();
  final GameHistoryService _history = GameHistoryService();

  GameSettings _settings = GameSettings.initial();
  List<Player> _players = [];
  List<Team> _teams = [];
  GameState _game = GameState.initial();
  String? _currentEditingPlayerId;
  Map<String, WordMetadata>? _wordMetadataCache;

  // Getters
  GameSettings get settings => _settings;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  GameState get game => _game;
  bool get isFiesta => _game.fiesta != null;
  String? get currentEditingPlayerId => _currentEditingPlayerId;

  // Setter pour le joueur en cours d'édition
  void setCurrentEditingPlayer(String? playerId) {
    _currentEditingPlayerId = playerId;
    notifyListeners();
  }

  /// Stocke les métadonnées des mots générés (mode aléatoire)
  void setWordMetadataCache(Map<String, WordMetadata> metadata) {
    _wordMetadataCache = metadata;
  }

  // Constructor
  GameProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      // 1. Toujours charger les paramètres (permanents)
      final savedSettings = await _storage.loadSettings();
      if (savedSettings != null) {
        _settings = GameSettings.fromJson(savedSettings);
      }

      // 2. Charger la session (joueurs/équipes sans mots)
      final savedSession = await _storage.loadGameSession();
      if (savedSession != null) {
        _players = (savedSession['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
        _teams = (savedSession['teams'] as List<dynamic>?)
                ?.map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
      }

      // 3. Charger l'état de jeu si existant (partie en cours avec mots)
      final savedState = await _storage.loadGameState();
      if (savedState != null) {
        // Si on a un état de jeu, charger les joueurs AVEC leurs mots
        _players = (savedState['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            _players;
        _teams = (savedState['teams'] as List<dynamic>?)
                ?.map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList() ??
            _teams;
        _game = GameState.fromJson(savedState['game'] ?? {});

        // 🔴 Reprendre AUSSI le tracking, pas seulement l'état de jeu. Sans ça,
        // une partie rouverte après un kill terminait sans jamais incrémenter
        // l'historique des mots — donc les mêmes mots ressortaient ensuite.
        // Durcir la boucle ne suffisait pas : il fallait durcir la REPRISE.
        final gameId = _game.gameId;
        if (gameId != null && _game.allWords.isNotEmpty) {
          await _analytics.resumeGame(gameId);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
    }
  }

  // Sauvegarde des paramètres (permanent)
  Future<void> _saveSettings() async {
    await _storage.saveSettings(_settings.toJson());
  }

  // Sauvegarde de la session (joueurs/équipes avec mots)
  Future<void> _saveGameSession() async {
    await _storage.saveGameSession({
      'players': _players.map((p) => p.toJson()).toList(),
      'teams': _teams.map((t) => t.toJson()).toList(),
    });
  }

  // Sauvegarde de l'état de jeu complet (partie en cours avec mots)
  Future<void> _saveGameState() async {
    await _storage.saveGameState({
      'players': _players.map((p) => p.toJson()).toList(),
      'teams': _teams.map((t) => t.toJson()).toList(),
      'game': _game.toJson(),
    });
  }

  // ========== ACTIONS - SETTINGS ==========

  void updateSettings({
    int? numberOfTeams,
    int? numberOfPlayers,
    String? wordChoice,
    int? totalWords,
    int? turnDuration,
    int? passPenalty,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
  }) {
    // Sauvegarder les anciennes valeurs pour détecter les changements
    final oldNumberOfTeams = _settings.numberOfTeams;
    final oldWordChoice = _settings.wordChoice;
    final oldCategories = _settings.selectedCategories;
    final oldDifficulties = _settings.selectedDifficultyLevels;

    // Mettre à jour les settings
    _settings = _settings.copyWith(
      numberOfTeams: numberOfTeams,
      numberOfPlayers: numberOfPlayers,
      wordChoice: wordChoice,
      totalWords: totalWords,
      turnDuration: turnDuration,
      passPenalty: passPenalty,
      selectedCategories: selectedCategories,
      selectedDifficultyLevels: selectedDifficultyLevels,
    );

    // Détecter les changements
    final modeChanged = wordChoice != null && wordChoice != oldWordChoice;
    final categoriesChanged = selectedCategories != null &&
        !_listEquals(selectedCategories, oldCategories);
    final difficultiesChanged = selectedDifficultyLevels != null &&
        !_listEquals(selectedDifficultyLevels, oldDifficulties);

    // Effacer les mots si :
    // 1. On change de mode (Aléatoire ↔ Personnalisé)
    // 2. OU on est en Aléatoire ET catégories/difficultés changent
    if (modeChanged ||
        (_settings.wordChoice == 'Aléatoire' &&
            (categoriesChanged || difficultiesChanged))) {
      _clearAllPlayersWords();
    }

    // Détecter le changement de nombre d'équipes
    final teamCountChanged =
        numberOfTeams != null && numberOfTeams != oldNumberOfTeams;

    // Recréer les équipes si le nombre change
    if (teamCountChanged && _teams.isNotEmpty) {
      createTeams();
    }

    notifyListeners();
    _saveSettings();
  }

  void toggleDifficultyLevel(int level) {
    final newLevels = List<int>.from(_settings.selectedDifficultyLevels);
    if (newLevels.contains(level)) {
      newLevels.remove(level);
    } else {
      newLevels.add(level);
    }
    newLevels.sort();
    updateSettings(selectedDifficultyLevels: newLevels);
  }

  // Compare deux listes
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Efface les mots de tous les joueurs
  void _clearAllPlayersWords() {
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(words: []);
    }
    _saveGameSession();
  }

  // ========== ACTIONS - PLAYERS ==========

  Map<String, dynamic> addPlayer(String name, {bool allowEmpty = false}) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty && !allowEmpty) {
      return {'error': 'Le nom est requis'};
    }

    if (trimmedName.isNotEmpty && _players.any((p) => p.name == trimmedName)) {
      return {'error': 'Ce nom existe déjà'};
    }

    final newPlayer = Player.create(trimmedName);
    _players.add(newPlayer);
    notifyListeners();
    _saveGameSession();

    return {'success': true, 'player': newPlayer};
  }

  void updatePlayer(String playerId, {String? name}) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(name: name);
      notifyListeners();
      _saveGameSession();
    }
  }

  void updatePlayerWords(String playerId, List<String> words) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(words: words);
      notifyListeners();
      _saveGameSession();
    }
  }

  void removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
    _saveGameSession();
  }

  void cleanupEmptyPlayers() {
    _players.removeWhere((p) => p.name.trim().isEmpty);
    notifyListeners();
    _saveGameSession();
  }

  // ========== ACTIONS - TEAMS ==========

  void createTeams() {
    _teams = List.generate(
      _settings.numberOfTeams,
      (i) => Team.create(i),
    );
    notifyListeners();
    _saveGameSession();
  }

  void updateTeamName(String teamId, String newName) {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      _teams[index] = _teams[index].copyWith(name: newName);
      notifyListeners();
      _saveGameSession();
    }
  }

  void movePlayerToTeam(String playerId, String teamId) {
    // Retirer le joueur de toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      if (_teams[i].playerIds.contains(playerId)) {
        final newPlayerIds = List<String>.from(_teams[i].playerIds)
          ..remove(playerId);
        _teams[i] = _teams[i].copyWith(playerIds: newPlayerIds);
      }
    }

    // Ajouter à la nouvelle équipe
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final newPlayerIds = List<String>.from(_teams[teamIndex].playerIds)
        ..add(playerId);
      _teams[teamIndex] = _teams[teamIndex].copyWith(playerIds: newPlayerIds);
    }

    notifyListeners();
    _saveGameSession();
  }

  void randomizeTeams() {
    final playersWithNames =
        _players.where((p) => p.name.trim().isNotEmpty).toList();
    final shuffledPlayers = List<Player>.from(playersWithNames)
      ..shuffle(Random());

    // Réinitialiser toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      _teams[i] = _teams[i].copyWith(playerIds: []);
    }

    // Distribuer les joueurs
    for (int i = 0; i < shuffledPlayers.length; i++) {
      final teamIndex = i % _settings.numberOfTeams;
      final newPlayerIds = List<String>.from(_teams[teamIndex].playerIds)
        ..add(shuffledPlayers[i].id);
      _teams[teamIndex] = _teams[teamIndex].copyWith(playerIds: newPlayerIds);
    }

    notifyListeners();
    _saveGameSession();
  }

  /// Synchronise les équipes avec les joueurs actuels
  /// - Supprime les joueurs invalides des équipes
  /// - Distribue les nouveaux joueurs aléatoirement dans l'équipe la plus petite
  void syncTeamsWithPlayers() {
    if (_teams.isEmpty) return;

    final validPlayerIds = _players.map((p) => p.id).toSet();
    final playersInTeams = <String>{};

    // 1. Supprimer les IDs de joueurs invalides de toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      final validIdsForTeam = _teams[i]
          .playerIds
          .where((id) => validPlayerIds.contains(id))
          .toList();
      _teams[i] = _teams[i].copyWith(playerIds: validIdsForTeam);
      playersInTeams.addAll(validIdsForTeam);
    }

    // 2. Trouver les joueurs non assignés (avec un nom)
    final unassignedPlayers = _players
        .where(
            (p) => p.name.trim().isNotEmpty && !playersInTeams.contains(p.id))
        .toList();

    // 3. Distribuer les nouveaux joueurs aléatoirement dans l'équipe la plus petite
    if (unassignedPlayers.isNotEmpty) {
      final shuffled = List<Player>.from(unassignedPlayers)..shuffle(Random());
      for (final player in shuffled) {
        // Trouver l'équipe avec le moins de joueurs
        int minIndex = 0;
        int minCount = _teams[0].playerIds.length;
        for (int i = 1; i < _teams.length; i++) {
          if (_teams[i].playerIds.length < minCount) {
            minCount = _teams[i].playerIds.length;
            minIndex = i;
          }
        }
        final newIds = List<String>.from(_teams[minIndex].playerIds)
          ..add(player.id);
        _teams[minIndex] = _teams[minIndex].copyWith(playerIds: newIds);
      }
    }

    notifyListeners();
    _saveGameSession();
  }

  // ========== ACTIONS - GAME ==========

  /// [fiesta] = configuration Fiesta à GELER dans la partie ; nul = Classique.
  ///
  /// 🔴 Le `copyWith` ci-dessous part de `_game` : sans `clearFiesta`, la
  /// config d'une partie Fiesta précédente survivrait à un lancement Classique.
  Future<void> startGame({FiestaRules? fiesta}) async {
    // Créer le pool de tous les mots
    final List<String> allWords = [];
    for (final player in _players) {
      allWords.addAll(player.words);
    }

    // Mélanger les mots
    final shuffledWords = List<String>.from(allWords)..shuffle(Random());

    // Générer l'ordre aléatoire des équipes et des joueurs
    final playOrder = _generatePlayOrder();

    // Obtenir le premier joueur
    final firstTeamIndex = playOrder['teamPlayOrder']![0];
    final firstPlayerIndex =
        playOrder['playerOrderByTeam']![_teams[firstTeamIndex].id]![0];

    // Générer un gameId unique pour cette partie
    final gameId = _userService.generateGameId();

    _game = _game.copyWith(
      gameId: gameId,
      currentScreen: AppConstants.screenGame,
      currentRound: 1,
      currentTurn: 1,
      currentTeamIndex: firstTeamIndex,
      currentPlayerIndexInTeam: firstPlayerIndex,
      teamPlayOrder: playOrder['teamPlayOrder'],
      playerOrderByTeam: playOrder['playerOrderByTeam'],
      currentTurnIndex: 0,
      allWords: shuffledWords,
      remainingWords: shuffledWords,
      currentWord: shuffledWords.isNotEmpty ? shuffledWords[0] : null,
      wordsGuessedThisTurn: [],
      passedWordsThisTurn: [],
      timeRemaining: _settings.turnDuration,
      clearTurnBonusTime: true,
      history: [],
      fiesta: fiesta == null ? null : FiestaState(rules: fiesta),
      clearFiesta: fiesta == null,
    );

    // Initialiser le tracking analytics
    await _initializeAnalytics(gameId, shuffledWords);

    notifyListeners();
    _saveGameState();
  }

  /// Initialise le tracking analytics pour une nouvelle partie
  Future<void> _initializeAnalytics(String gameId, List<String> words) async {
    // Créer les métadonnées des mots
    final wordMetadata = <String, WordMetadata>{};

    // En mode aléatoire, les mots ont des métadonnées de catégorie
    // En mode personnalisé, on lie les mots aux joueurs
    if (_settings.wordChoice == AppConstants.wordChoiceRandom) {
      // Mode aléatoire : utiliser le cache de métadonnées
      // Identifier les mots absents du cache (cache null ou incomplet)
      final missingWords = _wordMetadataCache == null
          ? words
          : words.where((w) => !_wordMetadataCache!.containsKey(w)).toList();

      // Lookup direct dans les catégories pour les mots manquants
      Map<String, WordMetadata> lookedUp = {};
      if (missingWords.isNotEmpty) {
        lookedUp = await lookupWordsMetadata(missingWords);
      }

      for (final word in words) {
        if (_wordMetadataCache != null &&
            _wordMetadataCache!.containsKey(word)) {
          wordMetadata[word] = _wordMetadataCache![word]!;
        } else if (lookedUp.containsKey(word)) {
          wordMetadata[word] = lookedUp[word]!;
        } else {
          // Dernier fallback (mot vraiment introuvable)
          wordMetadata[word] = WordMetadata(word: word);
        }
      }
    } else {
      // Mode personnalisé : lier les mots aux joueurs
      for (final player in _players) {
        for (final word in player.words) {
          wordMetadata[word] = WordMetadata.custom(
            word: word,
            submittedBy: player.id,
          );
        }
      }
    }

    await _analytics.startGame(
      gameId: gameId,
      numberOfPlayers: _players.length,
      numberOfTeams: _teams.length,
      totalWords: words.length,
      turnDuration: _settings.turnDuration,
      selectedCategories: _settings.selectedCategories,
      selectedDifficultyLevels: _settings.selectedDifficultyLevels,
      wordMetadata: wordMetadata,
    );
  }

  Map<String, dynamic> _generatePlayOrder() {
    // Mélanger l'ordre des équipes
    final shuffledTeamIndices = List<int>.generate(_teams.length, (i) => i)
      ..shuffle(Random());

    // On ne stocke que LE CYCLE, pas ses répétitions : l'ordre est périodique,
    // donc il se dérive (voir play_rotation.dart). Avant, la permutation était
    // recopiée 1000 fois — ~24 000 entiers pour 4 équipes et 20 joueurs,
    // ré-écrits sur disque à chaque mot deviné.
    final Map<String, List<int>> playerOrderByTeam = {};
    for (final team in _teams) {
      playerOrderByTeam[team.id] =
          List<int>.generate(team.playerIds.length, (i) => i)
            ..shuffle(Random());
    }

    return {
      'teamPlayOrder': shuffledTeamIndices,
      'playerOrderByTeam': playerOrderByTeam,
    };
  }

  void startTurn() {
    _game = _game.copyWith(
      currentScreen: AppConstants.screenCountdown,
      wordsGuessedThisTurn: [],
      passedWordsThisTurn: [],
      timeRemaining: _game.turnBonusTime ?? _settings.turnDuration,
    );

    notifyListeners();
    _saveGameState();
  }

  void startTurnTimer() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final durationSeconds = _game.turnBonusTime ?? _settings.turnDuration;
    final durationMs = durationSeconds * 1000;

    _game = _game.copyWith(
      currentScreen: AppConstants.screenTurn,
      turnStartTimestamp: now,
      turnEndTimestamp: now + durationMs,
      clearPausedTimeRemaining: true,
      clearPausedRemainingMs: true,
      timeRemaining: durationSeconds,
      clearTurnBonusTime: true,
    );

    // Tracker l'affichage du premier mot
    _trackWordShown();

    notifyListeners();
    _saveGameState();
  }

  /// Notifie le service analytics qu'un nouveau mot est affiché
  void _trackWordShown() {
    final currentWord = _game.currentWord;
    if (currentWord == null || !_analytics.isTracking) return;

    final currentTeam = getCurrentTeam();
    final currentPlayer = getCurrentPlayer();

    _analytics.onWordShown(
      word: currentWord,
      round: _game.currentRound,
      turn: _game.currentTurn,
      teamId: currentTeam?.id ?? '',
      playerId: currentPlayer?.id ?? '',
    );
  }

  void markWordAsGuessed() {
    final currentWord = _game.currentWord;
    if (currentWord == null) return;

    // Tracker le mot deviné AVANT de changer l'état
    _analytics.onWordGuessed(currentWord);

    final newGuessedWords = List<String>.from(_game.wordsGuessedThisTurn);
    if (!newGuessedWords.contains(currentWord)) {
      newGuessedWords.add(currentWord);
    }
    final newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    // Retirer le mot de passedWordsThisTurn s'il y était (mot recyclé puis deviné)
    final newPassedWords = List<String>.from(_game.passedWordsThisTurn)
      ..remove(currentWord);

    // Mélanger les mots restants
    newRemainingWords.shuffle(Random());

    // Fin de la manche si plus de mots
    if (newRemainingWords.isEmpty) {
      // Vérifier s'il reste des mots passés à recycler
      if (newPassedWords.isNotEmpty) {
        // Remettre les mots passés dans la pile
        final restoredWords = List<String>.from(newPassedWords)
          ..shuffle(Random());
        final nextCurrentWord = restoredWords[0];

        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: restoredWords,
          currentWord: nextCurrentWord,
        );

        // Tracker le nouveau mot affiché
        _trackWordShown();
      } else {
        // Vraie fin de manche (plus aucun mot disponible ni passé).
        //
        // 🔴 Ce chemin doit ARRÊTER l'horloge et reporter le temps restant en
        // bonus, exactement comme `endTurn`. Sans ça : la deadline restait
        // vivante pendant l'écran de vérification (le ticker pouvait encore
        // déclencher `endTurn`), et le temps gagné en finissant la manche en
        // avance était simplement perdu. C'était le seul des deux chemins vers
        // l'écran de vérification à ne pas le faire.
        final now = DateTime.now().millisecondsSinceEpoch;
        final bonusSeconds = turnClock.displayedSecondsAt(now);

        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: newRemainingWords,
          clearCurrentWord: true,
          currentScreen: AppConstants.screenVerification,
          turnBonusTime: bonusSeconds,
          timeRemaining: bonusSeconds,
          clearTurnStartTimestamp: true,
          clearTurnEndTimestamp: true,
          clearPausedTimeRemaining: true,
          clearPausedRemainingMs: true,
        );
      }
    } else {
      final newCurrentWord = newRemainingWords[0];

      _game = _game.copyWith(
        currentWord: newCurrentWord,
        remainingWords: newRemainingWords,
        wordsGuessedThisTurn: newGuessedWords,
        passedWordsThisTurn: newPassedWords,
      );

      // Tracker le nouveau mot affiché
      _trackWordShown();
    }

    notifyListeners();
    _saveGameState();
  }

  void passWord() {
    final passPenalty = _settings.passPenalty;
    final currentWord = _game.currentWord;
    final clock = turnClock;

    if (currentWord == null || !clock.isRunning) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Garde inchangée : elle porte sur la seconde AFFICHÉE, pas sur les ms.
    // C'est délibéré — passer avec « 5 » à l'écran et une pénalité de 5 reste
    // autorisé et met le chrono à zéro, comme avant. Comparer les ms refuserait
    // ce cas et changerait la règle du jeu en douce.
    if (clock.displayedSecondsAt(now) < passPenalty) return;

    // Tracker le pass AVANT de changer l'état
    _analytics.onWordPassed(currentWord);

    // La pénalité est retirée à la deadline, en ms exactes : plus de ré-ancrage
    // sur une seconde arrondie au supérieur (qui rendait du temps à chaque passe
    // et faisait remonter le chrono à pénalité 0).
    final newClock = clock.applyPenalty(passPenalty, now);

    final newPassedWords = List<String>.from(_game.passedWordsThisTurn);
    if (!newPassedWords.contains(currentWord)) {
      newPassedWords.add(currentWord);
    }
    var newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    // Si plus de mots restants, recycler les mots passés
    if (newRemainingWords.isEmpty && newPassedWords.isNotEmpty) {
      newRemainingWords = List<String>.from(newPassedWords);
    }

    newRemainingWords.shuffle(Random());
    final newCurrentWord =
        newRemainingWords.isNotEmpty ? newRemainingWords[0] : null;

    _game = _withClock(
      _game.copyWith(
        currentWord: newCurrentWord,
        passedWordsThisTurn: newPassedWords,
        remainingWords: newRemainingWords,
      ),
      newClock,
      nowMs: now,
    );

    // Tracker le nouveau mot affiché
    if (newCurrentWord != null) {
      _trackWordShown();
    }

    notifyListeners();
    _saveGameState();
  }

  void endTurn() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Passe par l'horloge : si le tour était GELÉ (app en arrière-plan, dialogue
    // ouvert), c'est le reste gelé qui compte — pas une deadline périmée.
    final timeRemaining = turnClock.displayedSecondsAt(now);

    // Si la manche n'est pas finie et qu'il y avait un mot en cours, le sauvegarder comme "expiré"
    final isRoundFinished = _game.remainingWords.isEmpty;
    final expiredWord = isRoundFinished ? null : _game.currentWord;

    // Tracker le mot expiré si applicable
    if (expiredWord != null) {
      _analytics.onWordExpired(expiredWord);
    }

    _game = _game.copyWith(
      timeRemaining: timeRemaining,
      currentScreen: AppConstants.screenVerification,
      turnBonusTime: isRoundFinished ? timeRemaining : null,
      expiredWord: expiredWord,
      clearExpiredWord: isRoundFinished,
      clearTurnStartTimestamp: true,
      clearTurnEndTimestamp: true,
      // Purger AUSSI le gel : sinon l'horloge reste « en pause » après la fin du
      // tour, et le `then` du dialogue « Terminer le tour » la reprend — ce qui
      // ré-arme une deadline sur l'écran de vérification.
      clearPausedTimeRemaining: true,
      clearPausedRemainingMs: true,
    );

    notifyListeners();
    _saveGameState();
  }

  // ========== TEMPS DU TOUR ==========
  //
  // 🔴 `TurnClock` est la SEULE autorité sur le temps de jeu. `turnEndTimestamp`
  // et `pausedTimeRemaining` ne sont que sa forme persistée : on ne les écrit
  // jamais à la main, on passe par [_applyClock].

  /// Reconstruit l'horloge depuis l'état persisté.
  TurnClock get turnClock {
    final end = _game.turnEndTimestamp;
    if (end != null) return TurnClock.endingAt(end);

    // Les millisecondes exactes font foi. Le champ en secondes n'est relu que
    // pour une partie mise en pause par une version ANTÉRIEURE de l'app, qui
    // ne l'écrivait pas — sinon on rendrait au joueur l'arrondi au supérieur.
    final pausedMs = _game.pausedRemainingMs;
    if (pausedMs != null) return TurnClock.frozen(pausedMs);

    final pausedSeconds = _game.pausedTimeRemaining;
    if (pausedSeconds != null) return TurnClock.frozen(pausedSeconds * 1000);

    return const TurnClock.stopped();
  }

  /// Écrit [clock] dans l'état, en gardant les deux champs persistés cohérents.
  ///
  /// L'un exclut l'autre : une deadline vivante ET un reste gelé, c'est
  /// exactement l'incohérence qui faisait terminer un tour au retour d'un
  /// dialogue.
  GameState _withClock(GameState state, TurnClock clock, {required int nowMs}) {
    return state.copyWith(
      turnEndTimestamp: clock.endTimestampMs,
      clearTurnEndTimestamp: clock.endTimestampMs == null,
      // Les ms exactes sont l'autorité ; la version en secondes reste écrite
      // pour qu'un downgrade éventuel retrouve un champ qu'il sait lire.
      pausedRemainingMs: clock.frozenRemainingMs,
      clearPausedRemainingMs: !clock.isPaused,
      pausedTimeRemaining:
          clock.isPaused ? (clock.frozenRemainingMs! / 1000).ceil() : null,
      clearPausedTimeRemaining: !clock.isPaused,
      timeRemaining: clock.displayedSecondsAt(nowMs),
    );
  }

  void _applyClock(TurnClock clock, {required int nowMs, bool persist = true}) {
    _game = _withClock(_game, clock, nowMs: nowMs);
    notifyListeners();
    if (persist) _saveGameState();
  }

  /// Gèle le tour en cours (dialogue ouvert, app en arrière-plan, appel entrant).
  ///
  /// Idempotent : appelable depuis plusieurs sources sans risque de double gel.
  void pauseTurn() {
    final clock = turnClock;
    if (!clock.isRunning) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _applyClock(clock.pauseAt(now), nowMs: now);
  }

  /// Reprend le tour là où il avait été gelé.
  void resumeTurn() {
    final clock = turnClock;
    if (!clock.isPaused) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _applyClock(clock.resumeAt(now), nowMs: now);
  }

  /// Rafraîchit la seconde affichée depuis l'horloge.
  ///
  /// ⚠️ N'émet une notification que lorsque la seconde CHANGE. L'ancien code
  /// poussait une valeur dix fois par seconde et notifiait à chaque tick, ce qui
  /// reconstruisait tout l'arbre sous le `Consumer` racine 10 fois/s.
  void refreshDisplayedTime() {
    final clock = turnClock;
    if (!clock.isRunning) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = clock.displayedSecondsAt(now);
    if (seconds == _game.timeRemaining) return;

    _game = _game.copyWith(timeRemaining: seconds);
    notifyListeners();
  }

  void validateWords(List<String> validatedWords) {
    final currentTeam = _teams[_game.currentTeamIndex];
    final passedWordsThisTurn = _game.passedWordsThisTurn;

    // Tout le CALCUL (classification, pool, score) vit dans `resolveTurn`, une
    // fonction pure et testée. Ne reste ici que ce qui a des effets de bord :
    // tracking analytics, mutation des équipes, avancement du tour.
    final resolution = resolveTurn(
      validatedWords: validatedWords,
      guessedThisTurn: _game.wordsGuessedThisTurn,
      passedThisTurn: passedWordsThisTurn,
      expiredWord: _game.expiredWord,
      currentPool: _game.remainingWords,
    );

    final allInvalidatedWords = resolution.allInvalidated;
    final newRemainingWords = resolution.remainingPool;
    final pointsScored = resolution.pointsScored;

    // Tracker les mots invalidés pour les analytics
    for (final word in allInvalidatedWords) {
      _analytics.onWordInvalidated(word);
    }

    // Tracker les mots passed/expired qui sont validés comme guessed
    for (final word in resolution.validatedPassed) {
      _analytics.onWordValidatedAsGuessed(word);
    }
    if (resolution.expiredValidated) {
      _analytics.onWordValidatedAsGuessed(resolution.expiredWord!);
    }

    // Mettre à jour le score
    final teamIndex = _teams.indexWhere((t) => t.id == currentTeam.id);
    if (teamIndex != -1) {
      final team = _teams[teamIndex];
      final newScore = team.score + pointsScored;
      final scoreByRound = List<int>.from(team.scoreByRound);
      scoreByRound[_game.currentRound - 1] += pointsScored;
      _teams[teamIndex] =
          team.copyWith(score: newScore, scoreByRound: scoreByRound);
    }

    // Vérifier si on doit fusionner avec l'entrée précédente (bonus time)
    // La fusion se fait toujours quand il y a un bonus pending, même avec des mots invalidés
    final hasBonusPending = _game.pendingBonusTurnId != null;
    final shouldMergeWithPrevious = hasBonusPending && _game.history.isNotEmpty;

    // Calculer le temps passé pour ce segment
    final currentTimeSpent = _settings.turnDuration - _game.timeRemaining;

    List<HistoryEntry> newHistory;
    int nextTurn;

    if (shouldMergeWithPrevious) {
      // Créer une entrée séparée pour le bonus time (pas de fusion)
      // Cela permet d'attribuer les mots à la bonne manche dans les stats
      final lastEntry = _game.history.last;
      final bonusEntry = HistoryEntry(
        round: _game.currentRound, // Manche actuelle (pas celle d'origine)
        turn: lastEntry.turn, // Même tour pour le graphique d'évolution
        teamId: lastEntry.teamId,
        playerId: lastEntry.playerId,
        wordsGuessed: validatedWords,
        wordsInvalidated: allInvalidatedWords,
        wordsPassed: passedWordsThisTurn,
        timeSpent: currentTimeSpent,
        isBonusContinuation: true, // Marquer comme continuation
      );
      // Ajouter l'entrée (pas de remplacement)
      newHistory = [..._game.history, bonusEntry];
      // Ne pas incrémenter le tour car c'est une continuation
      nextTurn = _game.currentTurn;
    } else {
      // Créer une nouvelle entrée normalement
      final historyEntry = HistoryEntry(
        round: _game.currentRound,
        turn: _game.currentTurn,
        teamId: currentTeam.id,
        playerId: currentTeam.playerIds[_game.currentPlayerIndexInTeam],
        wordsGuessed: validatedWords,
        wordsInvalidated: allInvalidatedWords,
        wordsPassed: passedWordsThisTurn,
        timeSpent: currentTimeSpent,
      );
      newHistory = [..._game.history, historyEntry];
      nextTurn = _game.currentTurn + 1;
    }

    // Calculer le prochain joueur
    final nextPlayer = _getNextPlayerWithRotation();

    // Fin de la manche?
    if (newRemainingWords.isEmpty) {
      // Préparer la fusion pour le bonus time si pas de mots invalidés
      final shouldPrepareBonusFusion = allInvalidatedWords.isEmpty;

      // Si c'est la dernière manche (manche 3), aller directement aux résultats
      final isLastRound = _game.currentRound >= 3;

      _game = _game.copyWith(
        history: newHistory,
        remainingWords: newRemainingWords,
        currentScreen: isLastRound
            ? AppConstants.screenResults
            : AppConstants.screenTransition,
        turnBonusTime: _game.timeRemaining,
        clearExpiredWord: true,
        pendingBonusTurnId: shouldPrepareBonusFusion ? _game.currentTurn : null,
        clearPendingBonusTurnId: !shouldPrepareBonusFusion,
      );

      // Dernière manche terminée : la partie est finie, on l'archive.
      if (isLastRound) _archiveGameResult();
    } else {
      // Mélanger les mots restants
      newRemainingWords.shuffle(Random());
      final nextCurrentWord = newRemainingWords[0];

      // Si des mots ont été invalidés, on perd le bonus
      final nextTurnBonusTime =
          allInvalidatedWords.isNotEmpty ? null : _game.turnBonusTime;

      _game = _game.copyWith(
        currentTurn: shouldMergeWithPrevious ? nextTurn : nextTurn,
        currentTurnIndex: nextPlayer['nextTurnIndex'],
        currentTeamIndex: nextPlayer['nextTeamIndex'],
        currentPlayerIndexInTeam: nextPlayer['nextPlayerIndexInTeam'],
        remainingWords: newRemainingWords,
        currentWord: nextCurrentWord,
        wordsGuessedThisTurn: [],
        passedWordsThisTurn: [],
        history: newHistory,
        currentScreen: AppConstants.screenGame,
        turnBonusTime: nextTurnBonusTime,
        clearTurnBonusTime: nextTurnBonusTime == null,
        clearExpiredWord: true,
        clearPendingBonusTurnId: true, // Réinitialiser après usage
      );
    }

    notifyListeners();
    _saveGameState();

    // Point de reprise du tracking : la fin d'un tour est le moment où un lot
    // d'événements est complet. On ne le fait PAS à chaque `_saveGameState()`
    // (appelé au moindre changement d'écran) — ce serait doubler l'écriture la
    // plus lourde de l'app pour rien.
    unawaited(_analytics.saveCurrentGame());
  }

  Map<String, int> _getNextPlayerWithRotation() {
    final nextTurnIndex = _game.currentTurnIndex + 1;

    // La longueur du cycle est le NOMBRE D'ÉQUIPES, pas la longueur de la liste
    // stockée : c'est ce qui rend le calcul identique sur une partie sauvegardée
    // à l'ancien format (permutation répétée 1000 fois) et sur le nouveau.
    final cycleLength = _teams.length;

    final nextTeamIndex = teamIndexAtTurn(
      teamPlayOrder: _game.teamPlayOrder,
      cycleLength: cycleLength,
      turnIndex: nextTurnIndex,
    );
    final nextTeam = _teams[nextTeamIndex];

    final nextPlayerIndexInTeam = playerIndexAtTurn(
      playerOrderForTeam: _game.playerOrderByTeam[nextTeam.id] ?? const [],
      cycleLength: cycleLength,
      turnIndex: nextTurnIndex,
    );

    return {
      'nextTurnIndex': nextTurnIndex,
      'nextTeamIndex': nextTeamIndex,
      'nextPlayerIndexInTeam': nextPlayerIndexInTeam,
    };
  }

  void nextRound() {
    final nextRoundNumber = _game.currentRound + 1;

    if (nextRoundNumber > 3) {
      _game = _game.copyWith(
        currentScreen: AppConstants.screenResults,
      );
      _archiveGameResult();
    } else {
      // Réinitialiser le pool de mots
      final shuffledWords = List<String>.from(_game.allWords)
        ..shuffle(Random());
      final nextCurrentWord = shuffledWords[0];

      _game = _game.copyWith(
        currentRound: nextRoundNumber,
        remainingWords: shuffledWords,
        currentWord: nextCurrentWord,
        wordsGuessedThisTurn: [],
        passedWordsThisTurn: [],
        currentScreen: AppConstants.screenGame,
      );
    }

    notifyListeners();
    _saveGameState();
  }

  /// Archive la partie terminée pour l'écran d'historique.
  ///
  /// On enregistre le résultat **tel qu'il a été montré aux joueurs**, pas une
  /// reconstruction depuis les events : la validation manuelle de fin de tour
  /// invalide des mots, les mots passés sont recyclés, et ces règles évolueront
  /// (mode Fiesta). Un score recalculé après coup finirait par diverger de celui
  /// affiché — et c'est le score affiché qui fait foi pour les joueurs.
  ///
  /// Volontairement fire-and-forget et enveloppé : l'archivage est une commodité,
  /// il ne doit jamais empêcher l'écran de résultats de s'afficher.
  void _archiveGameResult() {
    final gameId = _game.gameId;
    if (gameId == null || _teams.isEmpty) return;

    final result = GameResult(
      gameId: gameId,
      playedAt: DateTime.now(),
      teams: _teams
          .map((team) => TeamResult(
                id: team.id,
                name: team.name,
                score: team.score,
                scoreByRound: List<int>.from(team.scoreByRound),
                playerNames: team.playerIds
                    .map((id) => getPlayerById(id)?.name)
                    .whereType<String>()
                    .toList(),
              ))
          .toList(),
      totalWords: _game.allWords.length,
      turnDuration: _settings.turnDuration,
      roundsPlayed: _game.currentRound,
    );

    unawaited(_history.record(result));
  }

  // ========== ACTIONS - NAVIGATION ==========

  void goToScreen(String screenName) {
    _game = _game.copyWith(currentScreen: screenName);
    notifyListeners();
    // Sauvegarder seulement si une partie est en cours
    if (_game.isGameSuspended || _game.allWords.isNotEmpty) {
      _saveGameState();
    }
  }

  Future<void> suspendGame() async {
    // Sauvegarder les analytics en cours (au cas où l'app serait tuée)
    await _analytics.saveCurrentGame();

    final now = DateTime.now().millisecondsSinceEpoch;

    // 🔴 On GÈLE l'horloge au lieu de relire une deadline restée vivante.
    // Avant : l'écran mettait `_isPaused = true` sans toucher à la deadline,
    // puis cette méthode recalculait le reste depuis cette deadline périmée —
    // donc tout le temps passé dans le dialogue était décompté, et au-delà du
    // temps restant le `clamp` donnait 0, ce qui terminait le tour au retour.
    // La valeur correcte était pourtant déjà capturée par le widget, et ignorée.
    // `pauseAt` est idempotent : si l'écran a déjà gelé, on garde son reste.
    final frozen = turnClock.pauseAt(now);

    // Suspendre hors d'un tour (écran équipes, réglages…) : il n'y a pas
    // d'horloge à geler, mais l'ancien code posait quand même un reste égal au
    // temps affiché. On conserve ce comportement au lieu de le changer au
    // passage — ce n'est pas l'objet de ce correctif.
    final clock = frozen.isStopped
        ? TurnClock.frozen(_game.timeRemaining * 1000)
        : frozen;

    _game = _withClock(_game, clock, nowMs: now).copyWith(
      isGameSuspended: true,
      suspendedScreen: _game.currentScreen,
      currentScreen: AppConstants.screenHome,
    );

    notifyListeners();
    _saveGameState();
  }

  void resumeGame() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 🔴 Passer par `_withClock`, et non écrire les champs à la main : c'est CE
    // contournement qui rendait du temps au joueur. `suspendGame` écrivait un
    // reste arrondi à la seconde SUPÉRIEURE, `resumeGame` le relisait comme
    // exact — donc chaque aller-retour par l'accueil allongeait le tour de
    // jusqu'à 999 ms, autant de fois qu'on le répétait.
    _game = _withClock(_game, turnClock.resumeAt(now), nowMs: now).copyWith(
      currentScreen: _game.suspendedScreen ?? AppConstants.screenGame,
      isGameSuspended: false,
      clearSuspendedScreen: true,
    );

    notifyListeners();
    _saveGameState();
  }

  // ========== ACTIONS - RESET ==========

  // Efface les joueurs et équipes (utilisé quand on revient aux paramètres)
  void clearPlayersData() {
    _players = [];
    _teams = [];
    notifyListeners();
    _saveGameSession();
  }

  // Fin de partie normale → efface gameState, garde session pour "Rejouer"
  Future<void> endGameAndGoHome() async {
    // Terminer le tracking analytics et sauvegarder
    await _analytics.endGame();

    await _storage.clearGameState();
    _game = GameState.initial();
    notifyListeners();
  }

  // Nouvelle partie complète → efface session ET state, garde settings
  Future<void> startNewGame() async {
    // Terminer et sauvegarder les analytics si une partie était en cours
    if (_analytics.isTracking) {
      await _analytics.endGame();
    }

    await _storage.clearGameSession();
    await _storage.clearGameState();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
  }

  // Rejouer avec mêmes joueurs → efface mots, reset scores, va aux paramètres
  Future<void> restartWithSamePlayers() async {
    // Terminer et sauvegarder les analytics si une partie était en cours
    if (_analytics.isTracking) {
      await _analytics.endGame();
    }

    await _storage.clearGameState();

    // Effacer les mots de tous les joueurs
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(words: []);
    }

    // Reset scores des équipes
    for (int i = 0; i < _teams.length; i++) {
      _teams[i] = _teams[i].copyWith(
        score: 0,
        scoreByRound: [0, 0, 0],
      );
    }

    _game = GameState.initial()
        .copyWith(currentScreen: AppConstants.screenSettings);
    await _saveGameSession();
    notifyListeners();
  }

  // Réinitialise TOUT : paramètres, joueurs, mots, équipes, état de jeu
  Future<void> clearLocalStorage() async {
    await _storage.clearGameState();
    await _storage.clearGameSession();
    _settings = GameSettings.initial();
    await _saveSettings();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
  }

  // DEPRECATED: Utiliser startNewGame() à la place
  void resetGame() {
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
    _storage.clearGameSession();
    _storage.clearGameState();
  }

  // ========== HELPERS ==========

  Player? getPlayerById(String playerId) {
    try {
      return _players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  Team? getTeamById(String teamId) {
    try {
      return _teams.firstWhere((t) => t.id == teamId);
    } catch (e) {
      return null;
    }
  }

  Player? getCurrentPlayer() {
    if (_teams.isEmpty || _game.currentTeamIndex >= _teams.length) return null;
    final currentTeam = _teams[_game.currentTeamIndex];
    if (currentTeam.playerIds.isEmpty ||
        _game.currentPlayerIndexInTeam >= currentTeam.playerIds.length) {
      return null;
    }
    final playerId = currentTeam.playerIds[_game.currentPlayerIndexInTeam];
    return getPlayerById(playerId);
  }

  Team? getCurrentTeam() {
    if (_teams.isEmpty || _game.currentTeamIndex >= _teams.length) return null;
    return _teams[_game.currentTeamIndex];
  }

  List<Team> getTeamsSortedByScore() {
    final sortedTeams = List<Team>.from(_teams);
    sortedTeams.sort((a, b) {
      // D'abord par score décroissant
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;

      // En cas d'égalité, celui qui a commencé plus tard gagne
      final indexA = _teams.indexWhere((t) => t.id == a.id);
      final indexB = _teams.indexWhere((t) => t.id == b.id);
      final orderA = _game.teamPlayOrder.indexOf(indexA);
      final orderB = _game.teamPlayOrder.indexOf(indexB);

      // Plus grand = a commencé plus tard = meilleur classement
      return orderB.compareTo(orderA);
    });
    return sortedTeams;
  }

  bool get hasPlayersWithNames => _players.any((p) => p.name.trim().isNotEmpty);

  bool get allTeamsHaveMinPlayers =>
      _teams.every((t) => t.playerIds.length >= 2);

  int get totalWordsEntered =>
      _players.fold(0, (sum, p) => sum + p.words.length);

  int get expectedTotalWords => _settings.totalWords;

  /// Nombre effectif de mots restants (incluant les passés recyclables)
  int get effectiveRemainingWordsCount {
    final remainingSet = _game.remainingWords.toSet();

    // Mots passés qui ne sont PAS déjà dans remainingWords
    final passedNotInRemaining = _game.passedWordsThisTurn
        .where((w) => !remainingSet.contains(w))
        .length;

    // Total = remainingWords + passés non recyclés - mot actuel
    return _game.remainingWords.length + passedNotInRemaining - 1;
  }

  /// Retourne la distribution des mots par joueur
  /// Les premiers joueurs ont 1 mot de plus si la répartition est inégale
  Map<String, int> getWordsDistribution() {
    final playerCount = _players.length;
    if (playerCount == 0) return {};

    final baseWords = _settings.totalWords ~/ playerCount;
    final extraWords = _settings.totalWords % playerCount;

    final distribution = <String, int>{};
    for (int i = 0; i < _players.length; i++) {
      final wordsForPlayer = baseWords + (i < extraWords ? 1 : 0);
      distribution[_players[i].id] = wordsForPlayer;
    }
    return distribution;
  }

  /// Retourne le nombre de mots pour un joueur spécifique
  int getWordsCountForPlayer(String playerId) {
    final distribution = getWordsDistribution();
    return distribution[playerId] ?? 0;
  }

  // Vérifie si une session existe (joueurs d'une partie précédente)
  // Utilisé pour proposer "Rejouer" sur l'écran d'accueil
  bool get hasGameSession =>
      _players.isNotEmpty && _teams.isNotEmpty && !_game.isGameSuspended;

  // ========== NAVIGATION RETOUR ==========

  // Vérifie si c'est le tout premier tour de la partie
  bool get isFirstTurnOfGame =>
      _game.history.isEmpty && _game.currentRound == 1;

  // Vérifie si on peut revenir à l'écran de vérification
  bool get canGoBackToVerification => _game.preValidationSnapshot != null;

  // Sauvegarde l'état avant validation (appelé dans verification_screen)
  // validatedWords = les mots que l'utilisateur a choisi de valider
  //
  // 🔴 Le snapshot réutilise `GameState.toJson()`, la sérialisation CANONIQUE.
  // Avant, c'était une SECONDE sérialisation écrite à la main : 15 champs
  // recopiés, à re-synchroniser à chaque ajout de champ — et relus avec des
  // casts durs (`as int`, `as List`) qui levaient sur la moindre absence.
  // Un champ ajouté à GameState et oublié ici se traduisait par une restauration
  // silencieusement incomplète. C'est exactement le piège que le mode Fiesta
  // aurait déclenché, lui qui ajoutera des champs d'état par construction.
  void savePreValidationState(List<String> validatedWords) {
    _game = _game.copyWith(
      preValidationSnapshot: {
        // On retire le snapshot de lui-même : sans ça, chaque sauvegarde
        // imbriquerait la précédente et le blob grossirait sans fin.
        'game': _game.copyWith(clearPreValidationSnapshot: true).toJson(),
        'teamScores': _teams
            .map((t) => {
                  'id': t.id,
                  'score': t.score,
                  'scoreByRound': List<int>.from(t.scoreByRound),
                })
            .toList(),
        'validatedWords': List<String>.from(validatedWords),
      },
    );
    notifyListeners();
    _saveGameState();
  }

  // Restaure l'état avant validation (appelé quand on clique sur retour)
  void restorePreValidationState() {
    final snapshot = _game.preValidationSnapshot;
    if (snapshot == null) return;

    final gameJson = snapshot['game'];
    // Un snapshot écrit par l'ancienne version (format à plat) ou corrompu :
    // on renonce au retour arrière plutôt que de crasher. L'utilisateur perd la
    // possibilité de revenir sur CE tour, rien d'autre.
    if (gameJson is! Map<String, dynamic>) return;

    // Restaurer les scores des équipes
    final teamScores = snapshot['teamScores'];
    if (teamScores is List) {
      for (final ts in teamScores) {
        if (ts is! Map) continue;
        final idx = _teams.indexWhere((t) => t.id == ts['id']);
        if (idx != -1) {
          _teams[idx] = _teams[idx].copyWith(
            score: ts['score'] as int? ?? _teams[idx].score,
            scoreByRound: (ts['scoreByRound'] as List?)?.cast<int>() ??
                _teams[idx].scoreByRound,
          );
        }
      }
    }

    final validatedWords = snapshot['validatedWords'];

    _game = GameState.fromJson(gameJson).copyWith(
      currentScreen: AppConstants.screenVerification,
      clearPreValidationSnapshot: true,
      restoredValidatedWords:
          validatedWords is List ? validatedWords.cast<String>() : null,
    );

    notifyListeners();
    _saveGameState();
  }

  // Retour à l'écran de composition des équipes (premier tour uniquement)
  void goBackToTeams() {
    _game = _game.copyWith(
      currentScreen: AppConstants.screenTeams,
      clearPreValidationSnapshot: true,
    );
    notifyListeners();
  }

  // Efface les mots validés restaurés après utilisation par verification_screen
  void clearRestoredValidatedWords() {
    if (_game.restoredValidatedWords != null) {
      _game = _game.copyWith(clearRestoredValidatedWords: true);
      notifyListeners();
    }
  }
}
