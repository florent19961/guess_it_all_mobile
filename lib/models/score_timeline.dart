import 'dart:math';

import 'fiesta/fiesta_state.dart';
import 'game_state.dart';

/// Une manche sur le graphique : de l'étape [start] à l'étape [end].
class RoundSpan {
  final int round;
  final int start;
  final int end;

  const RoundSpan(
      {required this.round, required this.start, required this.end});
}

/// La partie vue par la révélation des scores. Une étape = une entrée
/// d'historique : une continuation en bonus a la sienne, dans sa manche.
class ScoreTimeline {
  /// Par équipe : score cumulé à chaque étape, de 0 à [steps].
  final List<List<int>> series;
  final List<RoundSpan> rounds;

  const ScoreTimeline({
    required this.series,
    required this.rounds,
  });

  int get steps => series.isEmpty ? 0 : series.first.length - 1;

  int get maxScore => series.fold(0, (m, s) => max(m, s.last));

  /// Valeur lissée de la courbe de [teamIndex] à l'étape [t] (Catmull-Rom,
  /// bornée entre deux étapes pour ne jamais dépasser ni reculer).
  double valueAt(int teamIndex, double t) {
    final s = series[teamIndex];
    final n = s.length - 1;
    if (n <= 0) return 0;
    final i = t.floor().clamp(0, n - 1);
    final u = (t - i).clamp(0.0, 1.0);
    final a = s[max(0, i - 1)].toDouble();
    final b = s[i].toDouble();
    final c = s[i + 1].toDouble();
    final d = s[min(n, i + 2)].toDouble();
    final v = .5 *
        (2 * b +
            (-a + c) * u +
            (2 * a - 5 * b + 4 * c - d) * u * u +
            (-a + 3 * b - 3 * c + d) * u * u * u);
    return v.clamp(min(b, c), max(b, c));
  }
}

ScoreTimeline buildScoreTimeline({
  required List<String> teamIds,
  required List<HistoryEntry> history,
}) {
  final series = [
    for (final _ in teamIds) <int>[0],
  ];
  final rounds = <RoundSpan>[];
  for (var i = 0; i < history.length; i++) {
    final entry = history[i];
    for (var team = 0; team < teamIds.length; team++) {
      final previous = series[team].last;
      series[team].add(
          teamIds[team] == entry.teamId ? previous + entry.points : previous);
    }
    if (rounds.isEmpty || rounds.last.round != entry.round) {
      rounds.add(RoundSpan(round: entry.round, start: i, end: i + 1));
    } else {
      rounds[rounds.length - 1] =
          RoundSpan(round: entry.round, start: rounds.last.start, end: i + 1);
    }
  }
  return ScoreTimeline(series: series, rounds: rounds);
}

/// L'étiquette de chaque équipe sur le graphique : ses prénoms, ou les noms
/// d'équipes pour toutes dès qu'une équipe dépasse 5 joueurs.
List<String> revealLabels({
  required List<String> teamNames,
  required List<List<String>> players,
}) =>
    players.any((p) => p.length > 5)
        ? teamNames
        : [for (final p in players) p.join(', ')];

/// L'entrée d'historique du tour où la cartouche a été jouée, -1 sans numéro de
/// tour (partie antérieure) ou tour introuvable. L'équipe compte : une
/// continuation partage son numéro de tour avec le tour qui la suit.
int entryOfCharge(ChargeUse use, List<HistoryEntry> history) => use.turn == null
    ? -1
    : history.indexWhere((h) =>
        h.turn == use.turn && h.round == use.round && h.teamId == use.teamId);

/// « Les Moulins gagnent ! », « Bob gagne ! ». Jamais d'égalité :
/// [winnerName] vient du classement (`compareFinalRank`).
String revealHeadline(String winnerName) => '${winnerLine(winnerName)} !';

/// « Les Moulins gagnent », « Bob gagne » : le verbe accordé au nom d'équipe.
String winnerLine(String winnerName) {
  final plural =
      RegExp(r'^(les|des|nos|vos|mes|ces|ses|leurs)\s', caseSensitive: false)
          .hasMatch(winnerName.trim());
  return '$winnerName ${plural ? 'gagnent' : 'gagne'}';
}
