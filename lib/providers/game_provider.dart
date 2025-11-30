import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  GameSettings _settings = GameSettings.initial();
  List<Player> _players = [];
  List<Team> _teams = [];
  GameState _game = GameState.initial();

  // Getters
  GameSettings get settings => _settings;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  GameState get game => _game;

  // Constructor
  GameProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final savedState = await _storage.loadGameState();
    if (savedState != null) {
      try {
        _settings = GameSettings.fromJson(savedState['settings'] ?? {});
        _players = (savedState['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
        _teams = (savedState['teams'] as List<dynamic>?)
                ?.map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
        _game = GameState.fromJson(savedState['game'] ?? {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } catch (e) {
        debugPrint('Erreur lors du chargement de l\'état sauvegardé: $e');
      }
    }
  }

  Future<void> _saveToStorage() async {
    await _storage.saveGameState({
      'settings': _settings.toJson(),
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
    int? wordsPerPlayer,
    int? turnDuration,
    int? passPenalty,
    List<String>? selectedCategories,
  }) {
    _settings = _settings.copyWith(
      numberOfTeams: numberOfTeams,
      numberOfPlayers: numberOfPlayers,
      wordChoice: wordChoice,
      wordsPerPlayer: wordsPerPlayer,
      turnDuration: turnDuration,
      passPenalty: passPenalty,
      selectedCategories: selectedCategories,
    );
    notifyListeners();
    _saveToStorage();
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
    _saveToStorage();

    return {'success': true, 'player': newPlayer};
  }

  void updatePlayer(String playerId, {String? name}) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(name: name);
      notifyListeners();
      _saveToStorage();
    }
  }

  void updatePlayerWords(String playerId, List<String> words) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(words: words);
      notifyListeners();
      _saveToStorage();
    }
  }

  void removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
    _saveToStorage();
  }

  void cleanupEmptyPlayers() {
    _players.removeWhere((p) => p.name.trim().isEmpty);
    notifyListeners();
    _saveToStorage();
  }

  // ========== ACTIONS - TEAMS ==========

  void createTeams() {
    _teams = List.generate(
      _settings.numberOfTeams,
      (i) => Team.create(i),
    );
    notifyListeners();
    _saveToStorage();
  }

  void updateTeamName(String teamId, String newName) {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      _teams[index] = _teams[index].copyWith(name: newName);
      notifyListeners();
      _saveToStorage();
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
    _saveToStorage();
  }

  void randomizeTeams() {
    final playersWithNames = _players.where((p) => p.name.trim().isNotEmpty).toList();
    final shuffledPlayers = List<Player>.from(playersWithNames)..shuffle(Random());

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
    _saveToStorage();
  }

  // ========== ACTIONS - GAME ==========

  void startGame() {
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

    _game = _game.copyWith(
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
    );

    notifyListeners();
    _saveToStorage();
  }

  Map<String, dynamic> _generatePlayOrder() {
    // Mélanger l'ordre des équipes
    final shuffledTeamIndices = List<int>.generate(_teams.length, (i) => i)
      ..shuffle(Random());

    // Créer un cycle (répéter 1000 fois)
    final List<int> teamPlayOrder = [];
    for (int i = 0; i < 1000; i++) {
      teamPlayOrder.addAll(shuffledTeamIndices);
    }

    // Pour chaque équipe, mélanger l'ordre de ses joueurs
    final Map<String, List<int>> playerOrderByTeam = {};
    for (final team in _teams) {
      final playerIndices = List<int>.generate(team.playerIds.length, (i) => i)
        ..shuffle(Random());

      // Créer un cycle pour les joueurs
      final List<int> cycledPlayerOrder = [];
      for (int i = 0; i < 1000; i++) {
        cycledPlayerOrder.addAll(playerIndices);
      }

      playerOrderByTeam[team.id] = cycledPlayerOrder;
    }

    return {
      'teamPlayOrder': teamPlayOrder,
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
    _saveToStorage();
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
      timeRemaining: durationSeconds,
    );

    notifyListeners();
    _saveToStorage();
  }

  void markWordAsGuessed() {
    final currentWord = _game.currentWord;
    if (currentWord == null) return;

    final newGuessedWords = List<String>.from(_game.wordsGuessedThisTurn)
      ..add(currentWord);
    final newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    // Mélanger les mots restants
    newRemainingWords.shuffle(Random());

    final newCurrentWord =
        newRemainingWords.isNotEmpty ? newRemainingWords[0] : null;

    // Fin de la manche si plus de mots
    if (newRemainingWords.isEmpty) {
      _game = _game.copyWith(
        wordsGuessedThisTurn: newGuessedWords,
        remainingWords: newRemainingWords,
        clearCurrentWord: true,
        currentScreen: AppConstants.screenVerification,
      );
    } else {
      _game = _game.copyWith(
        currentWord: newCurrentWord,
        remainingWords: newRemainingWords,
        wordsGuessedThisTurn: newGuessedWords,
      );
    }

    notifyListeners();
    _saveToStorage();
  }

  void passWord() {
    final passPenalty = _settings.passPenalty;
    final currentWord = _game.currentWord;
    final turnEndTimestamp = _game.turnEndTimestamp;

    if (currentWord == null || turnEndTimestamp == null) return;

    // Calculer le temps réel restant
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentRemaining = ((turnEndTimestamp - now) / 1000).ceil().clamp(0, 999);

    // Vérifier qu'il y a assez de temps
    if (currentRemaining < passPenalty) return;

    // Calculer le nouveau timestamp
    final newRemainingSeconds = currentRemaining - passPenalty;
    final newEndTimestamp = now + (newRemainingSeconds * 1000);

    final newPassedWords = List<String>.from(_game.passedWordsThisTurn)
      ..add(currentWord);
    final newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    newRemainingWords.shuffle(Random());
    final newCurrentWord =
        newRemainingWords.isNotEmpty ? newRemainingWords[0] : null;

    _game = _game.copyWith(
      currentWord: newCurrentWord,
      passedWordsThisTurn: newPassedWords,
      remainingWords: newRemainingWords,
      turnEndTimestamp: newEndTimestamp,
      timeRemaining: newRemainingSeconds,
    );

    notifyListeners();
    _saveToStorage();
  }

  void endTurn() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeRemaining = _game.turnEndTimestamp != null
        ? ((_game.turnEndTimestamp! - now) / 1000).ceil().clamp(0, 999)
        : 0;

    _game = _game.copyWith(
      timeRemaining: timeRemaining,
      currentScreen: AppConstants.screenVerification,
      turnBonusTime: _game.remainingWords.isEmpty ? timeRemaining : null,
      clearTurnStartTimestamp: true,
      clearTurnEndTimestamp: true,
    );

    notifyListeners();
    _saveToStorage();
  }

  void updateTimeRemaining(int time) {
    _game = _game.copyWith(timeRemaining: time);
    notifyListeners();
  }

  void validateWords(List<String> validatedWords) {
    final currentTeam = _teams[_game.currentTeamIndex];
    final wordsGuessedThisTurn = _game.wordsGuessedThisTurn;
    final passedWordsThisTurn = _game.passedWordsThisTurn;

    // Mots invalidés
    final invalidatedGuessedWords =
        wordsGuessedThisTurn.where((w) => !validatedWords.contains(w)).toList();
    final invalidatedPassedWords =
        passedWordsThisTurn.where((w) => !validatedWords.contains(w)).toList();
    final allInvalidatedWords = [
      ...invalidatedGuessedWords,
      ...invalidatedPassedWords
    ];

    // Remettre les mots invalidés dans le pool
    final newRemainingWords = List<String>.from(_game.remainingWords)
      ..addAll(allInvalidatedWords);

    // Calculer les points
    final pointsScored = validatedWords.length;

    // Mettre à jour le score
    final teamIndex = _teams.indexWhere((t) => t.id == currentTeam.id);
    if (teamIndex != -1) {
      final team = _teams[teamIndex];
      final newScore = team.score + pointsScored;
      final scoreByRound = List<int>.from(team.scoreByRound);
      scoreByRound[_game.currentRound - 1] += pointsScored;
      _teams[teamIndex] = team.copyWith(score: newScore, scoreByRound: scoreByRound);
    }

    // Ajouter à l'historique
    final historyEntry = HistoryEntry(
      round: _game.currentRound,
      turn: _game.currentTurn,
      teamId: currentTeam.id,
      playerId: currentTeam.playerIds[_game.currentPlayerIndexInTeam],
      wordsGuessed: validatedWords,
      wordsInvalidated: allInvalidatedWords,
      wordsPassed: passedWordsThisTurn,
      timeSpent: _settings.turnDuration - _game.timeRemaining,
    );

    // Calculer le prochain joueur
    final nextPlayer = _getNextPlayerWithRotation();

    // Fin de la manche?
    if (newRemainingWords.isEmpty) {
      _game = _game.copyWith(
        history: [..._game.history, historyEntry],
        remainingWords: newRemainingWords,
        currentScreen: AppConstants.screenTransition,
        turnBonusTime: _game.timeRemaining,
      );
    } else {
      // Mélanger les mots restants
      newRemainingWords.shuffle(Random());
      final nextCurrentWord = newRemainingWords[0];

      // Si des mots ont été invalidés, on perd le bonus
      final nextTurnBonusTime =
          allInvalidatedWords.isNotEmpty ? null : _game.turnBonusTime;

      _game = _game.copyWith(
        currentTurn: _game.currentTurn + 1,
        currentTurnIndex: nextPlayer['nextTurnIndex'],
        currentTeamIndex: nextPlayer['nextTeamIndex'],
        currentPlayerIndexInTeam: nextPlayer['nextPlayerIndexInTeam'],
        remainingWords: newRemainingWords,
        currentWord: nextCurrentWord,
        wordsGuessedThisTurn: [],
        passedWordsThisTurn: [],
        history: [..._game.history, historyEntry],
        currentScreen: AppConstants.screenGame,
        turnBonusTime: nextTurnBonusTime,
        clearTurnBonusTime: nextTurnBonusTime == null,
      );
    }

    notifyListeners();
    _saveToStorage();
  }

  Map<String, int> _getNextPlayerWithRotation() {
    final nextTurnIndex = _game.currentTurnIndex + 1;
    final nextTeamIndex = _game.teamPlayOrder[nextTurnIndex];
    final nextTeam = _teams[nextTeamIndex];

    // Compter combien de fois cette équipe a joué
    int teamPlayCount = 0;
    for (int i = 0; i <= nextTurnIndex; i++) {
      if (_game.teamPlayOrder[i] == nextTeamIndex) {
        teamPlayCount++;
      }
    }

    // Index du joueur
    final playerOrderForTeam = _game.playerOrderByTeam[nextTeam.id]!;
    final nextPlayerIndexInTeam =
        playerOrderForTeam[(teamPlayCount - 1) % playerOrderForTeam.length];

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
    } else {
      // Réinitialiser le pool de mots
      final shuffledWords = List<String>.from(_game.allWords)..shuffle(Random());
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
    _saveToStorage();
  }

  // ========== ACTIONS - NAVIGATION ==========

  void goToScreen(String screenName) {
    _game = _game.copyWith(currentScreen: screenName);
    notifyListeners();
    _saveToStorage();
  }

  void suspendGame() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pausedTime = _game.turnEndTimestamp != null
        ? ((_game.turnEndTimestamp! - now) / 1000).ceil().clamp(0, 999)
        : _game.timeRemaining;

    _game = _game.copyWith(
      isGameSuspended: true,
      suspendedScreen: _game.currentScreen,
      currentScreen: AppConstants.screenHome,
      pausedTimeRemaining: pausedTime,
      timeRemaining: pausedTime,
    );

    notifyListeners();
    _saveToStorage();
  }

  void resumeGame() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pausedTime = _game.pausedTimeRemaining ?? _game.timeRemaining;
    final newEndTimestamp = now + (pausedTime * 1000);

    _game = _game.copyWith(
      currentScreen: _game.suspendedScreen ?? AppConstants.screenGame,
      isGameSuspended: false,
      clearSuspendedScreen: true,
      turnEndTimestamp: newEndTimestamp,
    );

    notifyListeners();
    _saveToStorage();
  }

  // ========== ACTIONS - RESET ==========

  Future<void> clearLocalStorage() async {
    await _storage.clearGameState();
    _settings = GameSettings.initial();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
  }

  void resetGame() {
    _settings = GameSettings.initial();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
    _saveToStorage();
  }

  void restartWithSamePlayers() {
    // Reset scores
    for (int i = 0; i < _teams.length; i++) {
      _teams[i] = _teams[i].copyWith(
        score: 0,
        scoreByRound: [0, 0, 0],
      );
    }

    _game = GameState.initial();
    notifyListeners();
    _saveToStorage();
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
    sortedTeams.sort((a, b) => b.score.compareTo(a.score));
    return sortedTeams;
  }

  bool get hasPlayersWithNames =>
      _players.any((p) => p.name.trim().isNotEmpty);

  bool get allTeamsHaveMinPlayers =>
      _teams.every((t) => t.playerIds.length >= 2);

  int get totalWordsEntered =>
      _players.fold(0, (sum, p) => sum + p.words.length);

  int get expectedTotalWords =>
      _settings.numberOfPlayers * _settings.wordsPerPlayer;
}
