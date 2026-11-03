import '../../utils/constants.dart';
import '../game_result.dart';
import '../team.dart';
import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'symmetric_draw.dart';
import 'turn_time.dart';

/// Id du mode Fiesta pour les analytics et l'historique (story 2-7).
String fiestaModeId(FiestaRules rules) =>
    rules.mode == FiestaMode.auto ? 'fiesta_auto' : 'fiesta_custom';

/// Libellé du mode pour la carte des résultats (maquette `results`).
String fiestaModeLabel(FiestaRules rules) => rules.mode == FiestaMode.auto
    ? 'Fiesta · Auto'
    : 'Fiesta · ${rules.ensembleName ?? 'Personnalisé'}';

/// Récap « Modificateurs de la partie » en fin de partie : tirage par manche,
/// rattrapages.
///
/// RECALCULÉ, pas relu d'un journal : le tirage vient de la graine
/// `(gameId, manche)` (comme `nextRoundModifiers`) et le rattrapage des
/// scores cumulés en fin de manche, soit ce que la transition a montré. Rien à
/// persister pendant la partie. Les sections choix 1 parmi 3, bonus utilisés
/// et joueurs bloqués arrivent avec les stories qui les remplissent.
List<ModifierRecapLine> buildModifierRecap({
  required FiestaRules rules,
  required String gameId,
  required List<Team> teams,
  required int roundsPlayed,
}) {
  final lines = <ModifierRecapLine>[];

  for (var round = 1; round <= roundsPlayed; round++) {
    final names = roundModifiers(rules, gameId: gameId, round: round)
        .map((m) => modifierById(m.catalogId)?.name ?? m.catalogId)
        .toList();
    if (names.isEmpty) continue;
    lines.add(ModifierRecapLine(
      title: 'Manche $round · ${AppConstants.roundModes[round] ?? ''}',
      detail: names.join(' + '),
    ));
  }

  final catchUp = effectiveCatchUp(rules);
  if (catchUp != null) {
    final byTeam = <String, List<String>>{};
    // Après M1 et après M2 seulement, et seulement si la manche suivante a
    // été jouée.
    for (var round = 1; round <= 2 && round < roundsPlayed; round++) {
      final scores = {
        for (final t in teams)
          t.id: t.scoreByRound.take(round).fold(0, (a, b) => a + b),
      };
      for (final e
          in computeCatchUp(rules: catchUp, round: round, scores: scores)) {
        final sign = e.seconds < 0 ? '−' : '+';
        byTeam
            .putIfAbsent(e.teamId, () => [])
            .add('$sign${e.seconds.abs()} s (M${round + 1})');
      }
    }
    if (byTeam.isNotEmpty) {
      lines.add(ModifierRecapLine(
        title: 'Rattrapage',
        detail: teams
            .where((t) => byTeam.containsKey(t.id))
            .map((t) => '${t.name} ${byTeam[t.id]!.join(', ')}')
            .join(' · '),
      ));
    }
  }

  return lines;
}
