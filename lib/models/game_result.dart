import 'package:flutter/foundation.dart';

/// Résultat d'une équipe sur une partie terminée.
@immutable
class TeamResult {
  final String id;
  final String name;
  final int score;

  /// Score manche par manche (3 entrées en jeu normal).
  final List<int> scoreByRound;

  /// Noms des joueurs, figés au moment de la partie.
  ///
  /// On stocke les NOMS et pas les ids : les joueurs sont recréés à chaque
  /// partie, donc un id archivé ne désignerait plus rien. Un historique doit
  /// rester lisible sans dépendre d'un état qui n'existe plus.
  final List<String> playerNames;

  const TeamResult({
    required this.id,
    required this.name,
    required this.score,
    required this.scoreByRound,
    required this.playerNames,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'scoreByRound': scoreByRound,
        'playerNames': playerNames,
      };

  factory TeamResult.fromJson(Map<String, dynamic> json) => TeamResult(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        scoreByRound:
            (json['scoreByRound'] as List<dynamic>?)?.cast<int>() ?? const [],
        playerNames:
            (json['playerNames'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}

/// Une partie terminée, archivée pour l'historique.
///
/// 🔴 **Cette donnée n'existait pas.** `GameAnalytics` archivait la
/// configuration, les events et les stats par mot — mais **ni les scores, ni les
/// noms d'équipes, ni les joueurs**. Et `StatsScreen` lisait le provider *live*,
/// donc uniquement la partie en cours. Rien ne permettait de rouvrir l'app et de
/// revoir la soirée de la veille.
///
/// On ne recalcule pas les scores depuis les events : la validation manuelle de
/// fin de tour peut invalider des mots, les mots passés peuvent être recyclés,
/// et le résultat dépend de règles qui évolueront (mode Fiesta). Un score
/// reconstruit après coup finirait par diverger de celui affiché aux joueurs.
/// On archive donc le résultat **tel qu'il a été montré**.
@immutable
class GameResult {
  final String gameId;
  final DateTime playedAt;
  final List<TeamResult> teams;
  final int totalWords;
  final int turnDuration;
  final int roundsPlayed;

  const GameResult({
    required this.gameId,
    required this.playedAt,
    required this.teams,
    required this.totalWords,
    required this.turnDuration,
    required this.roundsPlayed,
  });

  /// Équipes triées par score décroissant.
  List<TeamResult> get ranking {
    final sorted = List<TeamResult>.from(teams);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  /// La ou les équipes en tête. Plusieurs en cas d'égalité — le jeu ne
  /// départage pas, donc l'historique ne doit pas inventer un vainqueur.
  List<TeamResult> get winners {
    if (teams.isEmpty) return const [];
    final best = teams.map((t) => t.score).reduce((a, b) => a > b ? a : b);
    return teams.where((t) => t.score == best).toList();
  }

  bool get isTie => winners.length > 1;

  /// Total de mots devinés, toutes équipes confondues.
  int get totalGuessed => teams.fold(0, (sum, t) => sum + t.score);

  int get playerCount => teams.fold(0, (sum, t) => sum + t.playerNames.length);

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'playedAt': playedAt.toIso8601String(),
        'teams': teams.map((t) => t.toJson()).toList(),
        'totalWords': totalWords,
        'turnDuration': turnDuration,
        'roundsPlayed': roundsPlayed,
      };

  /// Rend `null` si l'entrée est inexploitable, plutôt que de lever : une
  /// entrée d'historique abîmée ne doit pas rendre tout l'historique illisible.
  static GameResult? tryFromJson(Map<String, dynamic> json) {
    final gameId = json['gameId'];
    final playedAtRaw = json['playedAt'];
    if (gameId is! String || playedAtRaw is! String) return null;

    final playedAt = DateTime.tryParse(playedAtRaw);
    if (playedAt == null) return null;

    return GameResult(
      gameId: gameId,
      playedAt: playedAt,
      teams: (json['teams'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TeamResult.fromJson)
          .toList(),
      totalWords: json['totalWords'] as int? ?? 0,
      turnDuration: json['turnDuration'] as int? ?? 0,
      roundsPlayed: json['roundsPlayed'] as int? ?? 0,
    );
  }
}
