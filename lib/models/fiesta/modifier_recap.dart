import '../../utils/constants.dart';
import '../game_result.dart';
import '../team.dart';
import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'offers.dart';
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
/// persister pendant la partie. Exception : les bonus utilisés (2-9) sont
/// relus de [chargesUsed], seule trace d'une activation, et les cartes 1 parmi 3
/// de [offerChoices] (2-10). Le coup de pouce de l'app (Auto) est recalculé
/// comme le rattrapage.
List<ModifierRecapLine> buildModifierRecap({
  required FiestaRules rules,
  required String gameId,
  required List<Team> teams,
  required int roundsPlayed,
  List<ChargeUse> chargesUsed = const [],
  List<OfferChoice> offerChoices = const [],
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

  final teamName = {for (final t in teams) t.id: t.name};
  String mod(String id) => modifierById(id)?.name ?? id;
  String gift(String chooserId, ModifierInstance m) => m.teamId == chooserId
      ? '${teamName[chooserId] ?? '?'} : ${mod(m.catalogId)} (M${m.round})'
      : '${teamName[chooserId] ?? '?'} : ${mod(m.catalogId)} contre '
          '${teamName[m.teamId] ?? '?'} (M${m.round})';

  if (offerChoices.isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Choix 1 parmi 3',
      detail:
          offerChoices.map((c) => gift(c.chooserId, c.modifier)).join(' · '),
    ));
  }

  final boosts = <String>[];
  for (var round = 1; round <= 2 && round < roundsPlayed; round++) {
    if (!isAppBoostOn(rules, round)) continue;
    final standings = Standings({
      for (final t in teams)
        t.id: t.scoreByRound.take(round).fold(0, (a, b) => a + b),
    });
    for (final m in appBoost(
      rules: rules,
      gameId: gameId,
      round: round,
      standings: standings,
      roundDraw: roundModifiers(rules, gameId: gameId, round: round + 1),
    )) {
      final verb = m.nature == ModifierNature.bonus ? 'reçoit' : 'subit';
      boosts.add('${teamName[m.teamId] ?? '?'} $verb ${mod(m.catalogId)} '
          '(M${m.round})');
    }
  }
  if (boosts.isNotEmpty) {
    lines.add(ModifierRecapLine(
        title: 'Coup de pouce de l\'app', detail: boosts.join(' · ')));
  }

  if (chargesUsed.isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Bonus utilisés',
      detail: chargesUsed
          .map((u) => '${modifierById(u.catalogId)?.name ?? u.catalogId}, '
              '${teamName[u.teamId] ?? '?'} en M${u.round}')
          .join(' · '),
    ));
  }

  return lines;
}
