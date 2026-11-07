import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_analytics.dart';
import '../models/word_event.dart';
import '../models/word_stats.dart';
import 'user_service.dart';
import 'firebase_sync_service.dart';
import 'word_history_service.dart';

/// Le tour auquel appartient un événement. Fourni par l'appelant depuis
/// l'état PERSISTÉ de la partie à CHAQUE événement : il survit donc à un kill.
/// Le service ne le devine jamais. [modifiers] : ids Fiesta actifs pour
/// l'équipe qui joue, `null` en Classique.
typedef WordEventContext = ({
  int round,
  int turn,
  String teamId,
  String playerId,
  List<String>? modifiers,
});

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

  // Mot à l'écran → horodatage de son `shown`. Une entrée vit le temps de son
  // mot : retirée par `_recordEventWithDuration`. Mémoire seulement : perdue par un kill, d'où la durée inconnue ensuite.
  final Map<String, int> _shownAt = {};

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
    String? gameMode,
    Map<String, dynamic>? fiestaRules,
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
      gameMode: gameMode,
      fiestaRules: fiestaRules,
    );

    _clearTrackingState();
  }

  /// Reprend le tracking d'une partie déjà commencée, depuis le stockage local.
  ///
  /// 🔴 Sans ça, tuer l'app en pleine partie perdait le tracking DÉFINITIVEMENT :
  /// `_currentGame` repartait à `null`, `isTracking` restait faux, et `endGame()`
  /// sortait en early-return à la fin de partie. Or c'est `endGame()` qui
  /// incrémente `WordHistoryService` — donc l'impact n'était pas seulement une
  /// perte de télémétrie : la priorisation « mots jamais vus » ne s'appliquait
  /// plus, et **les mêmes mots ressortaient à la partie suivante**.
  ///
  /// Rend `true` si une partie non terminée a été retrouvée et reprise.
  Future<bool> resumeGame(String gameId) async {
    if (_currentGame?.gameId == gameId) return true;

    final saved = await loadGameAnalytics(gameId);
    // Une partie déjà clôturée ne se reprend pas : la ré-ouvrir rejouerait son
    // `endGame()`, donc un second `incrementWords` sur les mêmes mots.
    if (saved == null || saved.endedAt != null) return false;

    _currentGame = saved;
    _clearTrackingState();
    return true;
  }

  /// Oublie la partie en cours SANS la clôturer — simule un redémarrage.
  ///
  /// Le service est un singleton : sans ça, un test ne peut pas reproduire un
  /// kill d'application, qui est précisément le scénario que [resumeGame] rend
  /// survivable.
  @visibleForTesting
  void forgetCurrentGame() {
    _currentGame = null;
    _clearTrackingState();
  }

  /// Termine le tracking de la partie en cours
  Future<void> endGame() async {
    if (_currentGame == null) return;

    // Marquer la fin et calculer les stats
    _currentGame = _currentGame!.endGame().computeStats();

    // Sauvegarder la partie localement (toujours fait, même si sync échoue)
    await saveCurrentGame();

    // Incrémenter l'historique des mots joués
    final playedWords = _currentGame!.wordMetadata.keys.toList();
    if (playedWords.isNotEmpty) {
      await WordHistoryService().incrementWords(playedWords);
    }

    // Marquer pour synchronisation Firebase (fire-and-forget, ne bloque pas l'UI)
    // ignore: unawaited_futures
    FirebaseSyncService().markForSync(_currentGame!.gameId);

    // Nettoyer
    _currentGame = null;
    _clearTrackingState();
  }

  /// Remet à zéro l'état du tracking
  void _clearTrackingState() {
    _shownAt.clear();
  }

  // ========== TRACKING EN TEMPS RÉEL ==========

  /// Appelé quand un nouveau mot est affiché à un joueur.
  void onWordShown(String word, WordEventContext context) {
    if (_currentGame == null) return;
    _shownAt[word] = DateTime.now().millisecondsSinceEpoch;
    _addEvent(word, WordEventType.shown, context);
  }

  /// Appelé quand un mot est deviné
  void onWordGuessed(String word, WordEventContext context) =>
      _recordEventWithDuration(word, WordEventType.guessed, context);

  /// Appelé quand un mot est passé
  void onWordPassed(String word, WordEventContext context) =>
      _recordEventWithDuration(word, WordEventType.passed, context);

  /// Appelé quand le temps expire avec un mot affiché
  void onWordExpired(String word, WordEventContext context) =>
      _recordEventWithDuration(word, WordEventType.expired, context);

  /// Appelé quand un mot est invalidé lors de la vérification (sans durée :
  /// ça se passe après le tour).
  void onWordInvalidated(String word, WordEventContext context) =>
      _addEvent(word, WordEventType.invalidated, context);

  /// Appelé quand un mot passed/expired est validé comme guessed lors de la
  /// vérification (sans durée : validation a posteriori).
  void onWordValidatedAsGuessed(String word, WordEventContext context) =>
      _addEvent(word, WordEventType.guessed, context);

  /// Enregistre un événement avec sa durée depuis le `shown` de CE mot. Un mot
  /// sans `shown` en mémoire (affiché avant un kill) est enregistré quand même,
  /// SANS durée : jamais de durée inventée, jamais d'événement perdu.
  void _recordEventWithDuration(
      String word, WordEventType eventType, WordEventContext context) {
    if (_currentGame == null) return;
    final shownAt = _shownAt.remove(word);
    _addEvent(word, eventType, context, shownAt: shownAt);
  }

  void _addEvent(String word, WordEventType eventType, WordEventContext context,
      {int? shownAt}) {
    if (_currentGame == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentGame = _currentGame!.addEvent(WordEvent(
      word: word,
      eventType: eventType,
      timestamp: now,
      round: context.round,
      turn: context.turn,
      teamId: context.teamId,
      playerId: context.playerId,
      gameId: _currentGame!.gameId,
      durationMs: shownAt == null ? null : now - shownAt,
      modifiers: context.modifiers,
    ));
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
          final finalizedGame =
              game.copyWith(endedAt: DateTime.now()).computeStats();

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
