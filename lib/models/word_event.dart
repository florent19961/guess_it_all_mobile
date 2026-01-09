import 'package:uuid/uuid.dart';

/// Types d'événements possibles sur un mot
enum WordEventType {
  shown,       // Mot affiché à un joueur
  guessed,     // Mot deviné avec succès
  passed,      // Mot passé (skip)
  expired,     // Temps écoulé avec ce mot affiché
  invalidated, // Mot invalidé lors de la vérification
}

/// Événement atomique sur un mot pendant le jeu
///
/// Chaque action sur un mot génère un WordEvent qui permet de reconstruire
/// l'historique complet et calculer les statistiques détaillées.
class WordEvent {
  final String eventId;
  final String word;
  final WordEventType eventType;
  final int timestamp; // Unix timestamp en millisecondes
  final int round;
  final int turn;
  final String teamId;
  final String playerId;
  final String gameId;
  final int? durationMs; // Temps depuis 'shown' (null pour 'shown')

  WordEvent({
    String? eventId,
    required this.word,
    required this.eventType,
    required this.timestamp,
    required this.round,
    required this.turn,
    required this.teamId,
    required this.playerId,
    required this.gameId,
    this.durationMs,
  }) : eventId = eventId ?? const Uuid().v4();

  /// Factory pour créer un événement 'shown'
  factory WordEvent.shown({
    required String word,
    required int round,
    required int turn,
    required String teamId,
    required String playerId,
    required String gameId,
  }) {
    return WordEvent(
      word: word,
      eventType: WordEventType.shown,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      round: round,
      turn: turn,
      teamId: teamId,
      playerId: playerId,
      gameId: gameId,
      durationMs: null,
    );
  }

  /// Factory pour créer un événement avec durée
  factory WordEvent.withDuration({
    required String word,
    required WordEventType eventType,
    required int round,
    required int turn,
    required String teamId,
    required String playerId,
    required String gameId,
    required int shownTimestamp,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return WordEvent(
      word: word,
      eventType: eventType,
      timestamp: now,
      round: round,
      turn: turn,
      teamId: teamId,
      playerId: playerId,
      gameId: gameId,
      durationMs: now - shownTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'word': word,
    'eventType': eventType.name,
    'timestamp': timestamp,
    'round': round,
    'turn': turn,
    'teamId': teamId,
    'playerId': playerId,
    'gameId': gameId,
    'durationMs': durationMs,
  };

  factory WordEvent.fromJson(Map<String, dynamic> json) => WordEvent(
    eventId: json['eventId'] as String,
    word: json['word'] as String,
    eventType: WordEventType.values.firstWhere(
      (e) => e.name == json['eventType'],
    ),
    timestamp: json['timestamp'] as int,
    round: json['round'] as int,
    turn: json['turn'] as int,
    teamId: json['teamId'] as String,
    playerId: json['playerId'] as String,
    gameId: json['gameId'] as String,
    durationMs: json['durationMs'] as int?,
  );

  @override
  String toString() =>
      'WordEvent($eventType, "$word", round=$round, turn=$turn, duration=${durationMs}ms)';
}

/// Détail d'un événement de pass pour les statistiques agrégées
class PassEvent {
  final int timestamp;
  final int turn;
  final String teamId;
  final String playerId;
  final int durationMs; // Temps affiché avant le pass

  const PassEvent({
    required this.timestamp,
    required this.turn,
    required this.teamId,
    required this.playerId,
    required this.durationMs,
  });

  /// Créer depuis un WordEvent de type 'passed'
  factory PassEvent.fromWordEvent(WordEvent event) {
    if (event.eventType != WordEventType.passed) {
      throw ArgumentError('WordEvent must be of type passed');
    }
    return PassEvent(
      timestamp: event.timestamp,
      turn: event.turn,
      teamId: event.teamId,
      playerId: event.playerId,
      durationMs: event.durationMs ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'turn': turn,
    'teamId': teamId,
    'playerId': playerId,
    'durationMs': durationMs,
  };

  factory PassEvent.fromJson(Map<String, dynamic> json) => PassEvent(
    timestamp: json['timestamp'] as int,
    turn: json['turn'] as int,
    teamId: json['teamId'] as String,
    playerId: json['playerId'] as String,
    durationMs: json['durationMs'] as int,
  );

  @override
  String toString() =>
      'PassEvent(turn=$turn, team=$teamId, duration=${durationMs}ms)';
}
