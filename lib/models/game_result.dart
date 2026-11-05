import 'package:flutter/foundation.dart';

import 'game_setup_snapshot.dart';

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
        // `cast` est PARESSEUX : il ne lève qu'à la lecture de l'élément,
        // donc au rendu de l'écran et non au parsing. `whereType` filtre tout
        // de suite, et une valeur qui n'est pas une liste ne lève plus.
        scoreByRound: json['scoreByRound'] is List
            ? (json['scoreByRound'] as List<dynamic>).whereType<int>().toList()
            : const <int>[],
        playerNames: json['playerNames'] is List
            ? (json['playerNames'] as List<dynamic>)
                .whereType<String>()
                .toList()
            : const <String>[],
      );
}

/// Nature d'un fait du récap « Modificateurs de la partie ».
enum RecapKind {
  /// Tiré ou fixé pour toutes les équipes en manche [ModifierRecapItem.round].
  draw,

  /// Cartouche gagnée par [ModifierRecapItem.teamId] (coup de pouce à
  /// l'équipe menée). Les faits d'un genre retiré depuis, relus d'une archive,
  /// sont ignorés seuls ([ModifierRecapItem.tryFromJson]).
  boost,

  /// Charge dépensée par [ModifierRecapItem.teamId].
  bonusUsed,
}

/// Un fait du récap des modificateurs, archivé en DONNÉES (ids, manche) et
/// jamais en phrases : le texte est formé à l'affichage
/// (`formatModifierRecap`), donc traduisible plus tard (epic i18n).
@immutable
class ModifierRecapItem {
  final RecapKind kind;
  final int round;
  final String? catalogId;
  final String? teamId;
  final String? chooserId;

  const ModifierRecapItem(
    this.kind, {
    required this.round,
    this.catalogId,
    this.teamId,
    this.chooserId,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'round': round,
        if (catalogId != null) 'catalogId': catalogId,
        if (teamId != null) 'teamId': teamId,
        if (chooserId != null) 'chooserId': chooserId,
      };

  /// `null` si le fait est illisible (dont une ligne `{title, detail}`
  /// d'une version de dev antérieure) : ignoré seul.
  static ModifierRecapItem? tryFromJson(Map<String, dynamic> json) {
    final kind = RecapKind.values.asNameMap()[json['kind']];
    final round = json['round'];
    String? string(String key) => json[key] is String ? json[key] : null;
    if (kind == null || round is! int) return null;
    return ModifierRecapItem(
      kind,
      round: round,
      catalogId: string('catalogId'),
      teamId: string('teamId'),
      chooserId: string('chooserId'),
    );
  }
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

  /// `'fiesta_auto'` / `'fiesta_custom'` (story 2-7). `null` = Classique, ou
  /// partie archivée par une version antérieure : clé ABSENTE du JSON.
  final String? mode;

  /// Récap des modificateurs, `null` en Classique (clé absente).
  final List<ModifierRecapItem>? modifierRecap;

  /// Réglages de la partie, pour le « Rejouer » de l'historique. `null` =
  /// archive antérieure (clé absente) ou snapshot illisible.
  final GameSetupSnapshot? setup;

  const GameResult({
    required this.gameId,
    required this.playedAt,
    required this.teams,
    required this.totalWords,
    required this.turnDuration,
    required this.roundsPlayed,
    this.mode,
    this.modifierRecap,
    this.setup,
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
        // Additifs : une partie Classique archive exactement l'ancienne forme.
        if (mode != null) 'mode': mode,
        if (modifierRecap != null)
          'modifierRecap': modifierRecap!.map((l) => l.toJson()).toList(),
        if (setup != null) 'setup': setup!.toJson(),
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
      // 🔴 `as List<dynamic>?` LÈVE si `teams` est autre chose qu'un tableau —
      // un objet, par exemple. L'exception remontait hors du `.map()` (évalué
      // paresseusement par le `.toList()` de l'appelant), tombait dans le
      // `catch` générique de `load()`, et l'historique repartait VIDE sans
      // quarantaine : le `record()` suivant écrasait alors toutes les parties
      // saines. Le commentaire de `load()` promettait exactement l'inverse.
      teams: json['teams'] is List
          ? (json['teams'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(TeamResult.fromJson)
              .toList()
          : const <TeamResult>[],
      totalWords: json['totalWords'] as int? ?? 0,
      turnDuration: json['turnDuration'] as int? ?? 0,
      roundsPlayed: json['roundsPlayed'] as int? ?? 0,
      mode: json['mode'] is String ? json['mode'] as String : null,
      modifierRecap: json['modifierRecap'] is List
          ? (json['modifierRecap'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(ModifierRecapItem.tryFromJson)
              .whereType<ModifierRecapItem>()
              .toList()
          : null,
      setup: GameSetupSnapshot.tryFromJson(json['setup']),
    );
  }
}
