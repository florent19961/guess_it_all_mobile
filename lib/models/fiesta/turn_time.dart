import 'dart:math';

import 'fiesta_rules.dart';

/// Temps du tour (story 2-6) : rattrapage, malus de temps, composition de la
/// durée de départ. Tout est pur ; le provider ne fait que brancher.

/// Modificateurs de TEMPS : sans effet sur une continuation, qui joue
/// exactement ses secondes reportées ([composeTurnSeconds]).
const Set<String> kTimeModifierIds = {'minus_10s'};

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
/// - [carriedSeconds] non nul = tour de continuation : exactement ces
///   secondes, sans aucun modificateur de temps (Q1, Q5).
/// - Sinon : base + rattrapage − malus du leader − 10 s par [minus10sCount],
///   jamais sous [kTurnFloorSeconds] (Q4). Sans modificateur (Classique),
///   c'est la base.
TurnTime composeTurnSeconds({
  required int baseSeconds,
  int? carriedSeconds,
  int catchUpSeconds = 0,
  int leaderMalusSeconds = 0,
  int minus10sCount = 0,
}) {
  if (carriedSeconds != null) {
    return TurnTime(
      total: carriedSeconds,
      lines: [TurnTimeLine('Temps reporté', carriedSeconds)],
    );
  }
  final lines = [
    TurnTimeLine('Durée de base', baseSeconds),
    if (catchUpSeconds > 0) TurnTimeLine('Rattrapage', catchUpSeconds),
    if (leaderMalusSeconds > 0)
      TurnTimeLine('Malus du leader', -leaderMalusSeconds),
    if (minus10sCount > 0)
      TurnTimeLine(
        minus10sCount == 1 ? 'Malus de 10 s' : 'Malus de 10 s × $minus10sCount',
        -10 * minus10sCount,
      ),
  ];
  final sum = lines.fold(0, (acc, l) => acc + l.seconds);
  return TurnTime(total: max(kTurnFloorSeconds, sum), lines: lines);
}

/// Le rattrapage d'une équipe à la fin d'une manche (carte « Rattrapage »).
class CatchUpEntry {
  final String teamId;
  final bool isLeader;

  /// Écart mesuré : avec l'équipe en tête (menée) ou avec la 2ᵉ (leader).
  final int gap;

  /// Secondes par point d'écart, avant plafond.
  final int perPoint;

  /// Secondes dues : positives (bonus) ou négatives (malus du leader).
  final int seconds;

  const CatchUpEntry({
    required this.teamId,
    required this.isLeader,
    required this.gap,
    required this.perPoint,
    required this.seconds,
  });
}

/// Les curseurs de rattrapage qui s'appliquent à la partie, ou `null` si le
/// rattrapage est éteint : Auto → « Auto-calibrage » ; Personnalisé → ceux de
/// l'ensemble (tous à 0 = éteint, par construction de [computeCatchUp]).
CatchUpRules? effectiveCatchUp(FiestaRules rules) {
  if (rules.mode == FiestaMode.auto) {
    return rules.autoCalibrate ? CatchUpRules.auto : null;
  }
  return rules.catchUp;
}

/// Rattrapage dû à chaque équipe après la manche [round] (1 ou 2), sur
/// [scores] (id d'équipe → score à ce moment-là).
///
/// - Égalité générale : rien (Q3).
/// - Co-leaders : tous « en tête », malus mesuré sur la meilleure équipe non
///   leader (Q2, Q3). Jamais de rattrapage pour un leader.
/// - Menée : `min(cap, k × écart avec la tête)`, `k = b1` après M1, `b2`
///   après M2. Leader : `min(malCap, mal × écart avec la 2ᵉ)`.
///
/// Les équipes à 0 s n'apparaissent pas.
List<CatchUpEntry> computeCatchUp({
  required CatchUpRules rules,
  required int round,
  required Map<String, int> scores,
}) {
  if (scores.length < 2) return const [];
  final top = scores.values.reduce(max);
  final others = scores.values.where((s) => s < top);
  if (others.isEmpty) return const [];
  final second = others.reduce(max);
  final k = round == 1 ? rules.b1 : rules.b2;

  final entries = <CatchUpEntry>[];
  for (final entry in scores.entries) {
    final isLeader = entry.value == top;
    final gap = isLeader ? top - second : top - entry.value;
    final perPoint = isLeader ? rules.mal : k;
    final cap = isLeader ? rules.malCap : rules.cap;
    final seconds = min(cap, perPoint * gap);
    if (seconds <= 0) continue;
    entries.add(CatchUpEntry(
      teamId: entry.key,
      isLeader: isLeader,
      gap: gap,
      perPoint: perPoint,
      seconds: isLeader ? -seconds : seconds,
    ));
  }
  return entries;
}
