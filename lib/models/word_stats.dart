import 'word_event.dart';

/// Métadonnées d'un mot pour une partie
///
/// Stocke les informations contextuelles sur l'origine du mot.
class WordMetadata {
  final String word;
  final String? categoryId;    // ID de la catégorie (null si mode personnalisé)
  final int? difficulty;       // Niveau 1-3 (null si mode personnalisé)
  final String? submittedBy;   // Player ID qui a soumis (mode personnalisé)
  final String? language;      // 'french' | 'international'

  const WordMetadata({
    required this.word,
    this.categoryId,
    this.difficulty,
    this.submittedBy,
    this.language,
  });

  /// Factory pour un mot de catégorie (mode aléatoire)
  factory WordMetadata.fromCategory({
    required String word,
    required String categoryId,
    required int difficulty,
    String? language,
  }) {
    return WordMetadata(
      word: word,
      categoryId: categoryId,
      difficulty: difficulty,
      submittedBy: null,
      language: language,
    );
  }

  /// Factory pour un mot personnalisé (mode personnalisé)
  factory WordMetadata.custom({
    required String word,
    required String submittedBy,
  }) {
    return WordMetadata(
      word: word,
      categoryId: null,
      difficulty: null,
      submittedBy: submittedBy,
      language: null,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'categoryId': categoryId,
    'difficulty': difficulty,
    'submittedBy': submittedBy,
    'language': language,
  };

  factory WordMetadata.fromJson(Map<String, dynamic> json) => WordMetadata(
    word: json['word'] as String,
    categoryId: json['categoryId'] as String?,
    difficulty: json['difficulty'] as int?,
    submittedBy: json['submittedBy'] as String?,
    language: json['language'] as String?,
  );
}

/// Stats d'un mot pour une manche spécifique
///
/// À chaque manche, TOUS les mots doivent être devinés exactement 1 fois.
/// Un mot peut être passé plusieurs fois avant d'être deviné.
class WordRoundStats {
  final int round;                // 1, 2 ou 3
  final int timesPassed;          // Nombre de fois passé AVANT d'être deviné
  final int totalTimeMs;          // Temps cumulatif (tous les pass + deviné)
  final int guessTimeMs;          // Temps pris par l'équipe qui a deviné
  final String guessedByTeamId;
  final String guessedByPlayerId;
  final int guessedInTurn;
  final List<PassEvent> passEvents;

  const WordRoundStats({
    required this.round,
    required this.timesPassed,
    required this.totalTimeMs,
    required this.guessTimeMs,
    required this.guessedByTeamId,
    required this.guessedByPlayerId,
    required this.guessedInTurn,
    required this.passEvents,
  });

  /// Créer un WordRoundStats vide (pour initialisation)
  factory WordRoundStats.empty(int round) => WordRoundStats(
    round: round,
    timesPassed: 0,
    totalTimeMs: 0,
    guessTimeMs: 0,
    guessedByTeamId: '',
    guessedByPlayerId: '',
    guessedInTurn: 0,
    passEvents: const [],
  );

  /// Créer depuis une liste de WordEvent pour ce mot et cette manche
  factory WordRoundStats.fromEvents(int round, List<WordEvent> events) {
    // Filtrer les événements pour cette manche
    final roundEvents = events.where((e) => e.round == round).toList();

    // Trouver tous les pass
    final passEvents = roundEvents
        .where((e) => e.eventType == WordEventType.passed)
        .map((e) => PassEvent.fromWordEvent(e))
        .toList();

    // Trouver le DERNIER événement 'guessed' (ignore les guessed invalidés)
    final guessedEvent = roundEvents.lastWhere(
      (e) => e.eventType == WordEventType.guessed,
      orElse: () => throw StateError('No guessed event found for round $round'),
    );

    // Calculer le temps total (somme des pass + temps de deviné)
    final passTimeMs = passEvents.fold<int>(0, (sum, p) => sum + p.durationMs);
    final guessTimeMs = guessedEvent.durationMs ?? 0;
    final totalTimeMs = passTimeMs + guessTimeMs;

    return WordRoundStats(
      round: round,
      timesPassed: passEvents.length,
      totalTimeMs: totalTimeMs,
      guessTimeMs: guessTimeMs,
      guessedByTeamId: guessedEvent.teamId,
      guessedByPlayerId: guessedEvent.playerId,
      guessedInTurn: guessedEvent.turn,
      passEvents: passEvents,
    );
  }

  Map<String, dynamic> toJson() => {
    'round': round,
    'timesPassed': timesPassed,
    'totalTimeMs': totalTimeMs,
    'guessTimeMs': guessTimeMs,
    'guessedByTeamId': guessedByTeamId,
    'guessedByPlayerId': guessedByPlayerId,
    'guessedInTurn': guessedInTurn,
    'passEvents': passEvents.map((e) => e.toJson()).toList(),
  };

  factory WordRoundStats.fromJson(Map<String, dynamic> json) => WordRoundStats(
    round: json['round'] as int,
    timesPassed: json['timesPassed'] as int,
    totalTimeMs: json['totalTimeMs'] as int,
    guessTimeMs: json['guessTimeMs'] as int,
    guessedByTeamId: json['guessedByTeamId'] as String,
    guessedByPlayerId: json['guessedByPlayerId'] as String,
    guessedInTurn: json['guessedInTurn'] as int,
    passEvents: (json['passEvents'] as List)
        .map((e) => PassEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Stats agrégées d'un mot sur une partie complète (3 manches)
class WordStats {
  final String word;
  final WordMetadata metadata;
  final List<WordRoundStats> roundStats; // 3 éléments (M1, M2, M3)

  const WordStats({
    required this.word,
    required this.metadata,
    required this.roundStats,
  });

  // Getters pour les agrégats sur la partie
  int get totalTimesPassed =>
      roundStats.fold(0, (sum, r) => sum + r.timesPassed);

  int get totalTimeMs =>
      roundStats.fold(0, (sum, r) => sum + r.totalTimeMs);

  double get avgTotalTimeMs =>
      roundStats.isEmpty ? 0 : totalTimeMs / roundStats.length;

  int get totalGuessTimeMs =>
      roundStats.fold(0, (sum, r) => sum + r.guessTimeMs);

  double get avgGuessTimeMs =>
      roundStats.isEmpty ? 0 : totalGuessTimeMs / roundStats.length;

  /// Équipes qui ont deviné ce mot (par manche)
  List<String> get guessedByTeams =>
      roundStats.map((r) => r.guessedByTeamId).toList();

  /// Vérifie si le mot a été beaucoup passé (indicateur de difficulté)
  bool get isHighlyPassed => totalTimesPassed >= 5;

  /// Créer depuis les événements
  factory WordStats.fromEvents(
    String word,
    WordMetadata metadata,
    List<WordEvent> events,
  ) {
    // Filtrer les événements pour ce mot
    final wordEvents = events.where((e) => e.word == word).toList();

    // Créer les stats par manche
    final roundStats = <WordRoundStats>[];
    for (int round = 1; round <= 3; round++) {
      final hasGuessedInRound = wordEvents.any(
        (e) => e.round == round && e.eventType == WordEventType.guessed,
      );
      if (hasGuessedInRound) {
        roundStats.add(WordRoundStats.fromEvents(round, wordEvents));
      }
    }

    return WordStats(
      word: word,
      metadata: metadata,
      roundStats: roundStats,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'metadata': metadata.toJson(),
    'roundStats': roundStats.map((r) => r.toJson()).toList(),
  };

  factory WordStats.fromJson(Map<String, dynamic> json) => WordStats(
    word: json['word'] as String,
    metadata: WordMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    roundStats: (json['roundStats'] as List)
        .map((r) => WordRoundStats.fromJson(r as Map<String, dynamic>))
        .toList(),
  );

  @override
  String toString() =>
      'WordStats("$word", totalTime=${totalTimeMs}ms, passes=$totalTimesPassed)';
}
