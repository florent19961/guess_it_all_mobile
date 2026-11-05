import 'dart:math';

/// Temps du tour (story 2-6) : composition de la durée de départ. Tout est
/// pur ; le provider ne fait que brancher.

/// Plancher de la durée de départ d'un tour, après tous les malus (Q4).
const int kTurnFloorSeconds = 10;

/// Une composante de la durée du tour, pour la carte « Temps du tour ».
class TurnTimeLine {
  final String label;

  /// Signé : négatif pour un malus.
  final int seconds;

  const TurnTimeLine(this.label, this.seconds);
}

class TurnTime {
  /// Durée de départ du tour, en secondes.
  final int total;
  final List<TurnTimeLine> lines;

  const TurnTime({required this.total, required this.lines});
}

/// Durée de départ d'un tour et son détail.
///
/// 🔴 Seule source de la durée : l'aperçu d'avant-tour (`startTurn`) et le
/// chrono (`startTurnTimer`) passent tous deux par ici.
///
/// - [carriedSeconds] non nul = tour de continuation : ces secondes, + 10 s par
///   [plus10sCount] (un +10 s allumé pour cette partie du tour). Un −10 s reçu
///   a déjà pesé sur le début du tour : il ne se réapplique pas, sans plancher.
/// - Sinon : base + 10 s par [plus10sCount] − 10 s par [minus10sCount], jamais
///   sous [kTurnFloorSeconds] (Q4). Sans modificateur (Classique), c'est la
///   base.
TurnTime composeTurnSeconds({
  required int baseSeconds,
  int? carriedSeconds,
  int plus10sCount = 0,
  int minus10sCount = 0,
}) {
  if (carriedSeconds != null) {
    return TurnTime(
      total: carriedSeconds + 10 * plus10sCount,
      lines: [
        TurnTimeLine('Temps reporté', carriedSeconds),
        if (plus10sCount > 0) TurnTimeLine('Bonus de 10 s', 10 * plus10sCount),
      ],
    );
  }
  final lines = [
    TurnTimeLine('Durée de base', baseSeconds),
    if (plus10sCount > 0) TurnTimeLine('Bonus de 10 s', 10 * plus10sCount),
    if (minus10sCount > 0)
      TurnTimeLine(
        minus10sCount == 1 ? 'Malus de 10 s' : 'Malus de 10 s × $minus10sCount',
        -10 * minus10sCount,
      ),
  ];
  final sum = lines.fold(0, (acc, l) => acc + l.seconds);
  return TurnTime(total: max(kTurnFloorSeconds, sum), lines: lines);
}
