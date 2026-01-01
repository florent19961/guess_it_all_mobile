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
  String? _currentEditingPlayerId;

  // Getters
  GameSettings get settings => _settings;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  GameState get game => _game;
  String? get currentEditingPlayerId => _currentEditingPlayerId;

  // Setter pour le joueur en cours d'édition
  void setCurrentEditingPlayer(String? playerId) {
    _currentEditingPlayerId = playerId;
    notifyListeners();
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
        (_settings.wordChoice == 'Aléatoire' && (categoriesChanged || difficultiesChanged))) {
      _clearAllPlayersWords();
    }

    notifyListeners();
    _saveSettings();
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
        .where((p) => p.name.trim().isNotEmpty && !playersInTeams.contains(p.id))
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
    _saveGameState();
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
      timeRemaining: durationSeconds,
      clearTurnBonusTime: true,
    );

    notifyListeners();
    _saveGameState();
  }

  void markWordAsGuessed() {
    final currentWord = _game.currentWord;
    if (currentWord == null) return;

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
        final restoredWords = List<String>.from(newPassedWords)..shuffle(Random());
        final nextCurrentWord = restoredWords[0];

        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: restoredWords,
          currentWord: nextCurrentWord,
        );
      } else {
        // Vraie fin de manche (plus aucun mot disponible ni passé)
        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: newRemainingWords,
          clearCurrentWord: true,
          currentScreen: AppConstants.screenVerification,
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
    }

    notifyListeners();
    _saveGameState();
  }

  void passWord() {
    final passPenalty = _settings.passPenalty;
    final currentWord = _game.currentWord;
    final turnEndTimestamp = _game.turnEndTimestamp;

    if (currentWord == null || turnEndTimestamp == null) return;

    // Calculer le temps réel restant
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentRemaining =
        ((turnEndTimestamp - now) / 1000).ceil().clamp(0, 999);

    // Vérifier qu'il y a assez de temps
    if (currentRemaining < passPenalty) return;

    // Calculer le nouveau timestamp
    final newRemainingSeconds = currentRemaining - passPenalty;
    final newEndTimestamp = now + (newRemainingSeconds * 1000);

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

    _game = _game.copyWith(
      currentWord: newCurrentWord,
      passedWordsThisTurn: newPassedWords,
      remainingWords: newRemainingWords,
      turnEndTimestamp: newEndTimestamp,
      timeRemaining: newRemainingSeconds,
    );

    notifyListeners();
    _saveGameState();
  }

  void endTurn() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeRemaining = _game.turnEndTimestamp != null
        ? ((_game.turnEndTimestamp! - now) / 1000).ceil().clamp(0, 999)
        : 0;

    // Si la manche n'est pas finie et qu'il y avait un mot en cours, le sauvegarder comme "expiré"
    final isRoundFinished = _game.remainingWords.isEmpty;
    final expiredWord = isRoundFinished ? null : _game.currentWord;

    _game = _game.copyWith(
      timeRemaining: timeRemaining,
      currentScreen: AppConstants.screenVerification,
      turnBonusTime: isRoundFinished ? timeRemaining : null,
      expiredWord: expiredWord,
      clearExpiredWord: isRoundFinished,
      clearTurnStartTimestamp: true,
      clearTurnEndTimestamp: true,
    );

    notifyListeners();
    _saveGameState();
  }

  void updateTimeRemaining(int time) {
    _game = _game.copyWith(timeRemaining: time);
    notifyListeners();
  }

  void updateTurnEndTimestamp(int timestamp) {
    _game = _game.copyWith(turnEndTimestamp: timestamp);
    notifyListeners();
  }

  void validateWords(List<String> validatedWords) {
    final currentTeam = _teams[_game.currentTeamIndex];
    final wordsGuessedThisTurn = _game.wordsGuessedThisTurn;
    final passedWordsThisTurn = _game.passedWordsThisTurn;
    final expiredWord = _game.expiredWord;

    // Mots invalidés
    final invalidatedGuessedWords =
        wordsGuessedThisTurn.where((w) => !validatedWords.contains(w)).toList();
    final invalidatedPassedWords =
        passedWordsThisTurn.where((w) => !validatedWords.contains(w)).toList();

    // Gérer le mot expiré
    final isExpiredWordValidated =
        expiredWord != null && validatedWords.contains(expiredWord);
    final isExpiredWordInvalidated =
        expiredWord != null && !validatedWords.contains(expiredWord);

    final allInvalidatedWords = [
      ...invalidatedGuessedWords,
      ...invalidatedPassedWords,
      if (isExpiredWordInvalidated) expiredWord,
    ];

    // Remettre les mots invalidés dans le pool (Set garantit l'unicité)
    final newRemainingWords = <String>{
      ..._game.remainingWords,
      ...invalidatedGuessedWords,
      ...invalidatedPassedWords,
    }.toList();

    // Si le mot expiré est validé, le retirer du pool
    if (isExpiredWordValidated) {
      newRemainingWords.remove(expiredWord);
    }

    // Calculer les points
    final pointsScored = validatedWords.length;

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
    final shouldMergeWithPrevious = hasBonusPending &&
        _game.history.isNotEmpty;

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
        currentScreen: isLastRound ? AppConstants.screenResults : AppConstants.screenTransition,
        turnBonusTime: _game.timeRemaining,
        clearExpiredWord: true,
        pendingBonusTurnId: shouldPrepareBonusFusion ? _game.currentTurn : null,
        clearPendingBonusTurnId: !shouldPrepareBonusFusion,
      );
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

  // ========== ACTIONS - NAVIGATION ==========

  void goToScreen(String screenName) {
    _game = _game.copyWith(currentScreen: screenName);
    notifyListeners();
    // Sauvegarder seulement si une partie est en cours
    if (_game.isGameSuspended || _game.allWords.isNotEmpty) {
      _saveGameState();
    }
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
    _saveGameState();
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
    await _storage.clearGameState();
    _game = GameState.initial();
    notifyListeners();
  }

  // Nouvelle partie complète → efface session ET state, garde settings
  Future<void> startNewGame() async {
    await _storage.clearGameSession();
    await _storage.clearGameState();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    notifyListeners();
  }

  // Rejouer avec mêmes joueurs → efface mots, reset scores, va aux paramètres
  Future<void> restartWithSamePlayers() async {
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
  bool get canGoBackToVerification =>
      _game.preValidationSnapshot != null;

  // Sauvegarde l'état avant validation (appelé dans verification_screen)
  // validatedWords = les mots que l'utilisateur a choisi de valider
  void savePreValidationState(List<String> validatedWords) {
    _game = _game.copyWith(
      preValidationSnapshot: {
        'currentTeamIndex': _game.currentTeamIndex,
        'currentPlayerIndexInTeam': _game.currentPlayerIndexInTeam,
        'currentTurn': _game.currentTurn,
        'currentTurnIndex': _game.currentTurnIndex,
        'wordsGuessedThisTurn': List<String>.from(_game.wordsGuessedThisTurn),
        'passedWordsThisTurn': List<String>.from(_game.passedWordsThisTurn),
        'expiredWord': _game.expiredWord,
        'remainingWords': List<String>.from(_game.remainingWords),
        'currentWord': _game.currentWord,
        'timeRemaining': _game.timeRemaining,
        'turnBonusTime': _game.turnBonusTime,
        'history': _game.history.map((e) => e.toJson()).toList(),
        'teamScores': _teams.map((t) => {
          'id': t.id,
          'score': t.score,
          'scoreByRound': List<int>.from(t.scoreByRound),
        }).toList(),
        'pendingBonusTurnId': _game.pendingBonusTurnId,
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

    // Restaurer les scores des équipes
    final teamScores = snapshot['teamScores'] as List;
    for (final ts in teamScores) {
      final idx = _teams.indexWhere((t) => t.id == ts['id']);
      if (idx != -1) {
        _teams[idx] = _teams[idx].copyWith(
          score: ts['score'] as int,
          scoreByRound: List<int>.from(ts['scoreByRound'] as List),
        );
      }
    }

    // Restaurer l'historique
    final historyJson = snapshot['history'] as List;
    final restoredHistory = historyJson
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // Restaurer les mots validés par l'utilisateur
    final validatedWords = snapshot['validatedWords'] as List?;

    // Restaurer l'état du jeu
    _game = _game.copyWith(
      currentScreen: AppConstants.screenVerification,
      currentTeamIndex: snapshot['currentTeamIndex'] as int,
      currentPlayerIndexInTeam: snapshot['currentPlayerIndexInTeam'] as int,
      currentTurn: snapshot['currentTurn'] as int,
      currentTurnIndex: snapshot['currentTurnIndex'] as int,
      wordsGuessedThisTurn: List<String>.from(snapshot['wordsGuessedThisTurn'] as List),
      passedWordsThisTurn: List<String>.from(snapshot['passedWordsThisTurn'] as List),
      expiredWord: snapshot['expiredWord'] as String?,
      clearExpiredWord: snapshot['expiredWord'] == null,
      remainingWords: List<String>.from(snapshot['remainingWords'] as List),
      currentWord: snapshot['currentWord'] as String?,
      clearCurrentWord: snapshot['currentWord'] == null,
      timeRemaining: snapshot['timeRemaining'] as int,
      turnBonusTime: snapshot['turnBonusTime'] as int?,
      clearTurnBonusTime: snapshot['turnBonusTime'] == null,
      history: restoredHistory,
      pendingBonusTurnId: snapshot['pendingBonusTurnId'] as int?,
      clearPendingBonusTurnId: snapshot['pendingBonusTurnId'] == null,
      clearPreValidationSnapshot: true,
      restoredValidatedWords: validatedWords != null ? List<String>.from(validatedWords) : null,
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
