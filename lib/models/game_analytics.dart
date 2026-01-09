import 'word_event.dart';
import 'word_stats.dart';

/// Informations sur le device et l'application
class DeviceInfo {
  final String appVersion;
  final String platform;
  final String locale;
  final String? deviceModel;

  const DeviceInfo({
    required this.appVersion,
    required this.platform,
    required this.locale,
    this.deviceModel,
  });

  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'platform': platform,
    'locale': locale,
    'deviceModel': deviceModel,
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    appVersion: json['appVersion'] as String,
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    deviceModel: json['deviceModel'] as String?,
  );

  @override
  String toString() => 'DeviceInfo($platform, $appVersion, $locale)';
}

/// Analytics complètes d'une partie
///
/// Contient tous les événements bruts et les statistiques agrégées
/// pour l'analyse de la partie et l'analytics long terme.
class GameAnalytics {
  // Identifiants
  final String gameId;
  final String userId;

  // Métadonnées contextuelles
  final String appVersion;
  final String platform;
  final String locale;
  final String? deviceModel;

  // Timestamps
  final DateTime startedAt;
  final DateTime? endedAt;

  // Configuration de la partie
  final int numberOfPlayers;
  final int numberOfTeams;
  final int totalWords;
  final int turnDuration;
  final List<String> selectedCategories;
  final List<int> selectedDifficultyLevels;

  // Événements bruts (pour replay/debug/recalcul)
  final List<WordEvent> events;

  // Métadonnées des mots
  final Map<String, WordMetadata> wordMetadata;

  // Stats agrégées (calculées à partir des événements)
  final Map<String, WordStats> wordStats;

  GameAnalytics({
    required this.gameId,
    required this.userId,
    required this.appVersion,
    required this.platform,
    required this.locale,
    this.deviceModel,
    required this.startedAt,
    this.endedAt,
    required this.numberOfPlayers,
    required this.numberOfTeams,
    required this.totalWords,
    required this.turnDuration,
    required this.selectedCategories,
    required this.selectedDifficultyLevels,
    required this.events,
    required this.wordMetadata,
    required this.wordStats,
  });

  /// Factory pour créer une nouvelle partie
  factory GameAnalytics.create({
    required String gameId,
    required String userId,
    required DeviceInfo deviceInfo,
    required int numberOfPlayers,
    required int numberOfTeams,
    required int totalWords,
    required int turnDuration,
    required List<String> selectedCategories,
    required List<int> selectedDifficultyLevels,
    required Map<String, WordMetadata> wordMetadata,
  }) {
    return GameAnalytics(
      gameId: gameId,
      userId: userId,
      appVersion: deviceInfo.appVersion,
      platform: deviceInfo.platform,
      locale: deviceInfo.locale,
      deviceModel: deviceInfo.deviceModel,
      startedAt: DateTime.now(),
      endedAt: null,
      numberOfPlayers: numberOfPlayers,
      numberOfTeams: numberOfTeams,
      totalWords: totalWords,
      turnDuration: turnDuration,
      selectedCategories: selectedCategories,
      selectedDifficultyLevels: selectedDifficultyLevels,
      events: [],
      wordMetadata: wordMetadata,
      wordStats: {},
    );
  }

  /// Calcule les statistiques agrégées à partir des événements
  GameAnalytics computeStats() {
    final computedStats = <String, WordStats>{};

    // Grouper les événements par mot
    final eventsByWord = <String, List<WordEvent>>{};
    for (final event in events) {
      eventsByWord.putIfAbsent(event.word, () => []).add(event);
    }

    // Calculer les stats pour chaque mot
    for (final entry in eventsByWord.entries) {
      final word = entry.key;
      final wordEvents = entry.value;
      final metadata = wordMetadata[word];

      if (metadata != null) {
        computedStats[word] = WordStats.fromEvents(word, metadata, wordEvents);
      }
    }

    return copyWith(wordStats: computedStats);
  }

  /// Marque la fin de la partie
  GameAnalytics endGame() {
    return copyWith(endedAt: DateTime.now());
  }

  /// Ajoute un événement
  GameAnalytics addEvent(WordEvent event) {
    return copyWith(events: [...events, event]);
  }

  /// Durée totale de la partie en secondes
  int? get durationSeconds {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt).inSeconds;
  }

  /// Nombre total d'événements
  int get totalEvents => events.length;

  /// Nombre de mots passés au total (toutes manches)
  int get totalPasses => events
      .where((e) => e.eventType == WordEventType.passed)
      .length;

  /// Nombre de mots devinés au total (toutes manches)
  int get totalGuessed => events
      .where((e) => e.eventType == WordEventType.guessed)
      .length;

  /// Mot le plus difficile (plus de temps total)
  WordStats? get hardestWord {
    if (wordStats.isEmpty) return null;
    return wordStats.values.reduce(
      (a, b) => a.totalTimeMs > b.totalTimeMs ? a : b,
    );
  }

  /// Mot le plus passé
  WordStats? get mostPassedWord {
    if (wordStats.isEmpty) return null;
    return wordStats.values.reduce(
      (a, b) => a.totalTimesPassed > b.totalTimesPassed ? a : b,
    );
  }

  /// Mot le plus rapide
  WordStats? get fastestWord {
    if (wordStats.isEmpty) return null;
    return wordStats.values.reduce(
      (a, b) => a.totalTimeMs < b.totalTimeMs ? a : b,
    );
  }

  GameAnalytics copyWith({
    String? gameId,
    String? userId,
    String? appVersion,
    String? platform,
    String? locale,
    String? deviceModel,
    DateTime? startedAt,
    DateTime? endedAt,
    int? numberOfPlayers,
    int? numberOfTeams,
    int? totalWords,
    int? turnDuration,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
    List<WordEvent>? events,
    Map<String, WordMetadata>? wordMetadata,
    Map<String, WordStats>? wordStats,
  }) {
    return GameAnalytics(
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      locale: locale ?? this.locale,
      deviceModel: deviceModel ?? this.deviceModel,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      totalWords: totalWords ?? this.totalWords,
      turnDuration: turnDuration ?? this.turnDuration,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedDifficultyLevels:
          selectedDifficultyLevels ?? this.selectedDifficultyLevels,
      events: events ?? this.events,
      wordMetadata: wordMetadata ?? this.wordMetadata,
      wordStats: wordStats ?? this.wordStats,
    );
  }

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'userId': userId,
    'appVersion': appVersion,
    'platform': platform,
    'locale': locale,
    'deviceModel': deviceModel,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'numberOfPlayers': numberOfPlayers,
    'numberOfTeams': numberOfTeams,
    'totalWords': totalWords,
    'turnDuration': turnDuration,
    'selectedCategories': selectedCategories,
    'selectedDifficultyLevels': selectedDifficultyLevels,
    'events': events.map((e) => e.toJson()).toList(),
    'wordMetadata': wordMetadata.map((k, v) => MapEntry(k, v.toJson())),
    'wordStats': wordStats.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory GameAnalytics.fromJson(Map<String, dynamic> json) => GameAnalytics(
    gameId: json['gameId'] as String,
    userId: json['userId'] as String,
    appVersion: json['appVersion'] as String,
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    deviceModel: json['deviceModel'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    numberOfPlayers: json['numberOfPlayers'] as int,
    numberOfTeams: json['numberOfTeams'] as int,
    totalWords: json['totalWords'] as int,
    turnDuration: json['turnDuration'] as int,
    selectedCategories: (json['selectedCategories'] as List).cast<String>(),
    selectedDifficultyLevels:
        (json['selectedDifficultyLevels'] as List).cast<int>(),
    events: (json['events'] as List)
        .map((e) => WordEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    wordMetadata: (json['wordMetadata'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, WordMetadata.fromJson(v as Map<String, dynamic>)),
    ),
    wordStats: (json['wordStats'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, WordStats.fromJson(v as Map<String, dynamic>)),
    ),
  );

  @override
  String toString() =>
      'GameAnalytics(gameId=$gameId, events=${events.length}, words=${wordStats.length})';
}
