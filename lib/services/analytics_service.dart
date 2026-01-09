import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_analytics.dart';
import '../models/word_event.dart';
import '../models/word_stats.dart';
import 'user_service.dart';
import 'firebase_sync_service.dart';

/// Service de tracking et de persistance des analytics
///
/// Ce service est un singleton qui gère :
/// - Le tracking en temps réel des événements pendant une partie
/// - La persistance des analytics multi-parties
/// - Le calcul des statistiques agrégées
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Clés de stockage
  static const String _analyticsIndexKey = 'guessItAll_analytics_index';
  static const String _analyticsPrefix = 'guessItAll_analytics_';

  // Configuration
  static const int defaultRetentionCount = 50; // Garder 50 parties max

  // État du tracking
  GameAnalytics? _currentGame;
  int? _lastShownTimestamp;
  String? _lastShownWord;
  int? _lastRound;
  int? _lastTurn;
  String? _lastTeamId;
  String? _lastPlayerId;

  /// Vérifie si une partie est en cours de tracking
  bool get isTracking => _currentGame != null;

  /// Retourne les analytics de la partie en cours
  GameAnalytics? get currentGame => _currentGame;

  // ========== LIFECYCLE ==========

  /// Démarre le tracking d'une nouvelle partie
  Future<void> startGame({
    required String gameId,
    required int numberOfPlayers,
    required int numberOfTeams,
    required int totalWords,
    required int turnDuration,
    required List<String> selectedCategories,
    required List<int> selectedDifficultyLevels,
    required Map<String, WordMetadata> wordMetadata,
  }) async {
    final userService = UserService();
    final userId = await userService.getUserId();
    final deviceInfo = await userService.getDeviceInfo();

    _currentGame = GameAnalytics.create(
      gameId: gameId,
      userId: userId,
      deviceInfo: deviceInfo,
      numberOfPlayers: numberOfPlayers,
      numberOfTeams: numberOfTeams,
      totalWords: totalWords,
      turnDuration: turnDuration,
      selectedCategories: selectedCategories,
      selectedDifficultyLevels: selectedDifficultyLevels,
      wordMetadata: wordMetadata,
    );

    _clearTrackingState();
  }

  /// Termine le tracking de la partie en cours
  Future<void> endGame() async {
    if (_currentGame == null) return;

    // Marquer la fin et calculer les stats
    _currentGame = _currentGame!.endGame().computeStats();

    // Sauvegarder la partie localement (toujours fait, même si sync échoue)
    await saveCurrentGame();

    // Marquer pour synchronisation Firebase (fire-and-forget, ne bloque pas l'UI)
    // ignore: unawaited_futures
    FirebaseSyncService().markForSync(_currentGame!.gameId);

    // Nettoyer
    _currentGame = null;
    _clearTrackingState();
  }

  /// Remet à zéro l'état du tracking
  void _clearTrackingState() {
    _lastShownTimestamp = null;
    _lastShownWord = null;
    _lastRound = null;
    _lastTurn = null;
    _lastTeamId = null;
    _lastPlayerId = null;
  }

  // ========== TRACKING EN TEMPS RÉEL ==========

  /// Appelé quand un nouveau mot est affiché à un joueur
  void onWordShown({
    required String word,
    required int round,
    required int turn,
    required String teamId,
    required String playerId,
  }) {
    if (_currentGame == null) return;

    // Mémoriser pour calculer la durée
    _lastShownTimestamp = DateTime.now().millisecondsSinceEpoch;
    _lastShownWord = word;
    _lastRound = round;
    _lastTurn = turn;
    _lastTeamId = teamId;
    _lastPlayerId = playerId;

    // Enregistrer l'événement 'shown'
    final event = WordEvent.shown(
      word: word,
      round: round,
      turn: turn,
      teamId: teamId,
      playerId: playerId,
      gameId: _currentGame!.gameId,
    );

    _currentGame = _currentGame!.addEvent(event);
  }

  /// Appelé quand un mot est deviné
  void onWordGuessed(String word) {
    _recordEventWithDuration(word, WordEventType.guessed);
  }

  /// Appelé quand un mot est passé
  void onWordPassed(String word) {
    _recordEventWithDuration(word, WordEventType.passed);
  }

  /// Appelé quand le temps expire avec un mot affiché
  void onWordExpired(String word) {
    _recordEventWithDuration(word, WordEventType.expired);
  }

  /// Appelé quand un mot est invalidé lors de la vérification
  void onWordInvalidated(String word) {
    if (_currentGame == null) return;

    // Pour l'invalidation, on n'a pas de durée car ça se passe après le tour
    final event = WordEvent(
      word: word,
      eventType: WordEventType.invalidated,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      round: _lastRound ?? 1,
      turn: _lastTurn ?? 1,
      teamId: _lastTeamId ?? '',
      playerId: _lastPlayerId ?? '',
      gameId: _currentGame!.gameId,
      durationMs: null,
    );

    _currentGame = _currentGame!.addEvent(event);
  }

  /// Appelé quand un mot passed/expired est validé comme guessed lors de la vérification
  void onWordValidatedAsGuessed(String word) {
    if (_currentGame == null) return;

    // Créer un event guessed sans durée (validation a posteriori)
    final event = WordEvent(
      word: word,
      eventType: WordEventType.guessed,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      round: _lastRound ?? 1,
      turn: _lastTurn ?? 1,
      teamId: _lastTeamId ?? '',
      playerId: _lastPlayerId ?? '',
      gameId: _currentGame!.gameId,
      durationMs: null, // Pas de durée car validation a posteriori
    );

    _currentGame = _currentGame!.addEvent(event);
  }

  /// Enregistre un événement avec calcul de durée
  void _recordEventWithDuration(String word, WordEventType eventType) {
    if (_currentGame == null) return;
    if (_lastShownTimestamp == null || word != _lastShownWord) return;

    final event = WordEvent.withDuration(
      word: word,
      eventType: eventType,
      round: _lastRound ?? 1,
      turn: _lastTurn ?? 1,
      teamId: _lastTeamId ?? '',
      playerId: _lastPlayerId ?? '',
      gameId: _currentGame!.gameId,
      shownTimestamp: _lastShownTimestamp!,
    );

    _currentGame = _currentGame!.addEvent(event);

    // Reset après l'événement (sauf pour 'shown' qui reste en mémoire)
    _lastShownTimestamp = null;
    _lastShownWord = null;
  }

  // ========== PERSISTANCE ==========

  /// Sauvegarde la partie en cours
  Future<void> saveCurrentGame() async {
    if (_currentGame == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Sauvegarder les analytics
      final key = '$_analyticsPrefix${_currentGame!.gameId}';
      await prefs.setString(key, jsonEncode(_currentGame!.toJson()));

      // Mettre à jour l'index
      final index = await _loadIndex();
      if (!index.contains(_currentGame!.gameId)) {
        index.add(_currentGame!.gameId);
        await prefs.setString(_analyticsIndexKey, jsonEncode(index));
      }

      // Nettoyer les vieilles parties si nécessaire
      await pruneOldGames(defaultRetentionCount);
    } catch (_) {
      // Erreur silencieuse - les données seront resauvegardées plus tard
    }
  }

  /// Charge une partie par son gameId
  Future<GameAnalytics?> loadGameAnalytics(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_analyticsPrefix$gameId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      return GameAnalytics.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Charge toutes les parties
  Future<List<GameAnalytics>> loadAllGames() async {
    final games = <GameAnalytics>[];

    try {
      final index = await _loadIndex();

      for (final gameId in index) {
        final game = await loadGameAnalytics(gameId);
        if (game != null) {
          games.add(game);
        }
      }

      // Trier par date (plus récent en premier)
      games.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      // Erreur silencieuse
    }

    return games;
  }

  /// Supprime une partie
  Future<void> deleteGameAnalytics(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Supprimer les données
      final key = '$_analyticsPrefix$gameId';
      await prefs.remove(key);

      // Mettre à jour l'index
      final index = await _loadIndex();
      index.remove(gameId);
      await prefs.setString(_analyticsIndexKey, jsonEncode(index));
    } catch (_) {
      // Erreur silencieuse
    }
  }

  /// Supprime les parties les plus anciennes pour ne garder que keepCount
  Future<void> pruneOldGames(int keepCount) async {
    try {
      final games = await loadAllGames();

      if (games.length <= keepCount) return;

      // Supprimer les plus anciennes (la liste est triée par date décroissante)
      final toDelete = games.skip(keepCount).toList();

      for (final game in toDelete) {
        await deleteGameAnalytics(game.gameId);
      }
    } catch (_) {
      // Erreur silencieuse
    }
  }

  /// Finalise les parties orphelines (sauvegardées mais non terminées)
  ///
  /// Appelé au démarrage de l'app pour récupérer les analytics
  /// des parties interrompues par un kill.
  /// Les parties récupérées sont automatiquement marquées pour sync Firebase.
  Future<int> finalizeOrphanedGames() async {
    int count = 0;
    final recoveredGameIds = <String>[];

    try {
      final games = await loadAllGames();

      for (final game in games) {
        // Partie orpheline = pas de endedAt mais des events
        if (game.endedAt == null && game.events.isNotEmpty) {
          // Calculer les stats et marquer comme terminée
          final finalizedGame = game
              .copyWith(endedAt: DateTime.now())
              .computeStats();

          // Sauvegarder directement dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final key = '$_analyticsPrefix${game.gameId}';
          await prefs.setString(key, jsonEncode(finalizedGame.toJson()));

          recoveredGameIds.add(game.gameId);
          count++;
        }
      }

      // Marquer les parties récupérées pour synchronisation Firebase
      final syncService = FirebaseSyncService();
      for (final gameId in recoveredGameIds) {
        await syncService.markForSync(gameId);
      }
    } catch (_) {
      // Erreur silencieuse
    }

    return count;
  }

  /// Charge l'index des gameIds
  Future<List<String>> _loadIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_analyticsIndexKey);

      if (jsonString == null) return [];

      return (jsonDecode(jsonString) as List).cast<String>();
    } catch (e) {
      return [];
    }
  }

  // ========== STATISTIQUES AGRÉGÉES ==========

  /// Calcule les statistiques agrégées pour la partie en cours
  Map<String, WordStats> computeWordStats() {
    if (_currentGame == null) return {};
    return _currentGame!.computeStats().wordStats;
  }

  /// Retourne les mots les plus difficiles (temps total élevé)
  List<WordStats> getHardestWords({int limit = 10}) {
    if (_currentGame?.wordStats.isEmpty ?? true) return [];

    final stats = _currentGame!.wordStats.values.toList();
    stats.sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

    return stats.take(limit).toList();
  }

  /// Retourne les mots les plus passés
  List<WordStats> getMostPassedWords({int limit = 10}) {
    if (_currentGame?.wordStats.isEmpty ?? true) return [];

    final stats = _currentGame!.wordStats.values.toList();
    stats.sort((a, b) => b.totalTimesPassed.compareTo(a.totalTimesPassed));

    return stats.take(limit).toList();
  }

  /// Retourne les mots les plus rapides
  List<WordStats> getFastestWords({int limit = 10}) {
    if (_currentGame?.wordStats.isEmpty ?? true) return [];

    final stats = _currentGame!.wordStats.values.toList();
    stats.sort((a, b) => a.totalTimeMs.compareTo(b.totalTimeMs));

    return stats.take(limit).toList();
  }

  /// Statistiques par catégorie
  Map<String, int> getStatsByCategory() {
    if (_currentGame?.wordStats.isEmpty ?? true) return {};

    final result = <String, int>{};

    for (final stats in _currentGame!.wordStats.values) {
      final categoryId = stats.metadata.categoryId ?? 'custom';
      result[categoryId] = (result[categoryId] ?? 0) + stats.totalTimeMs;
    }

    return result;
  }

  /// Statistiques par difficulté
  Map<int, int> getStatsByDifficulty() {
    if (_currentGame?.wordStats.isEmpty ?? true) return {};

    final result = <int, int>{};

    for (final stats in _currentGame!.wordStats.values) {
      final difficulty = stats.metadata.difficulty ?? 0;
      result[difficulty] = (result[difficulty] ?? 0) + stats.totalTimeMs;
    }

    return result;
  }
}
