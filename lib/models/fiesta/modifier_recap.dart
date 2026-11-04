import '../../utils/constants.dart';
import '../game_result.dart';
import '../team.dart';
import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'round_transition.dart';
import 'symmetric_draw.dart';

/// Id du mode Fiesta pour les analytics et l'historique (story 2-7).
String fiestaModeId(FiestaRules rules) =>
    rules.mode == FiestaMode.auto ? 'fiesta_auto' : 'fiesta_custom';

/// Libellé du mode pour la carte des résultats (maquette `results`).
String fiestaModeLabel(FiestaRules rules) => rules.mode == FiestaMode.auto
    ? 'Fiesta · Auto'
    : 'Fiesta · ${rules.ensembleName ?? 'Personnalisé'}';

/// Une ligne AFFICHÉE du récap « Modificateurs de la partie » : titre et
/// détail formés depuis les faits archivés. Jamais persistée.
class ModifierRecapLine {
  final String title;
  final String detail;

  const ModifierRecapLine({required this.title, required this.detail});
}

/// Récap « Modificateurs de la partie » en fin de partie, en FAITS (ids,
/// manche, secondes) : c'est ce qui est archivé, le texte est formé à
/// l'affichage par [formatModifierRecap].
///
/// RECALCULÉ, pas relu d'un journal : le tirage vient de la graine
/// `(gameId, manche)` et le rattrapage des scores cumulés en fin de manche,
/// soit ce que la transition a montré (même plan, `planRoundTransition`).
/// Exceptions : les cartouches utilisées (2-9, lane 2), relues de
/// [chargesUsed], et les
/// cartes 1 parmi 3 de [offerChoices] (2-10).
List<ModifierRecapItem> buildModifierRecap({
  required FiestaRules rules,
  required String gameId,
  required List<Team> teams,
  required int roundsPlayed,
  List<ChargeUse> chargesUsed = const [],
  List<OfferChoice> offerChoices = const [],
}) {
  final fiesta = FiestaState(rules: rules, offerChoices: offerChoices);
  final transitions = [
    // Après M1 et après M2 seulement, si la manche suivante a été jouée.
    for (var round = 1; round <= 2 && round < roundsPlayed; round++)
      planRoundTransition(
        fiesta: fiesta,
        gameId: gameId,
        finishedRound: round,
        scores: {
          for (final t in teams)
            t.id: t.scoreByRound.take(round).fold(0, (a, b) => a + b),
        },
      )!,
  ];
  return [
    for (var round = 1; round <= roundsPlayed; round++)
      for (final m in roundModifiers(rules, gameId: gameId, round: round))
        ModifierRecapItem(RecapKind.draw, round: round, catalogId: m.catalogId),
    for (final plan in transitions)
      for (final e in plan.catchUp)
        ModifierRecapItem(RecapKind.catchUp,
            round: plan.round, teamId: e.teamId, seconds: e.seconds),
    for (final c in offerChoices)
      ModifierRecapItem(RecapKind.choice,
          round: c.modifier.round,
          catalogId: c.modifier.catalogId,
          teamId: c.modifier.teamId,
          chooserId: c.chooserId),
    for (final plan in transitions)
      for (final m in plan.gifts)
        ModifierRecapItem(RecapKind.boost,
            round: m.round, catalogId: m.catalogId, teamId: m.teamId),
    // Un malus infligé : `chooserId` = qui l'a joué, `teamId` = sa cible.
    for (final u in chargesUsed)
      ModifierRecapItem(RecapKind.bonusUsed,
          round: u.round,
          catalogId: u.catalogId,
          teamId: u.targetTeamId ?? u.teamId,
          chooserId: u.targetTeamId == null ? null : u.teamId),
  ];
}

/// Lignes affichées du récap, depuis ses faits. [teamNames] : id → nom, dans
/// l'ordre des équipes (ordre des lignes du rattrapage).
List<ModifierRecapLine> formatModifierRecap(
  List<ModifierRecapItem> items, {
  required Map<String, String> teamNames,
}) {
  String mod(String? id) => modifierById(id ?? '')?.name ?? id ?? '?';
  String team(String? id) => teamNames[id] ?? '?';
  Iterable<ModifierRecapItem> of(RecapKind kind) =>
      items.where((i) => i.kind == kind);
  String joined(RecapKind kind, String Function(ModifierRecapItem) line) =>
      of(kind).map(line).join(' · ');

  final lines = <ModifierRecapLine>[];
  for (var round = 1; round <= 3; round++) {
    final names = of(RecapKind.draw)
        .where((i) => i.round == round)
        .map((i) => mod(i.catalogId));
    if (names.isEmpty) continue;
    lines.add(ModifierRecapLine(
      title: 'Manche $round · ${AppConstants.roundModes[round] ?? ''}',
      detail: names.join(' + '),
    ));
  }

  String catchUp(ModifierRecapItem i) {
    final s = i.seconds ?? 0;
    return '${s < 0 ? '−' : '+'}${s.abs()} s (M${i.round})';
  }

  final catchUpTeams = teamNames.keys
      .where((id) => of(RecapKind.catchUp).any((i) => i.teamId == id));
  if (catchUpTeams.isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Rattrapage',
      detail: catchUpTeams
          .map((id) =>
              '${team(id)} ${of(RecapKind.catchUp).where((i) => i.teamId == id).map(catchUp).join(', ')}')
          .join(' · '),
    ));
  }

  if (of(RecapKind.choice).isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Choix 1 parmi 3',
      detail: joined(
          RecapKind.choice,
          (i) => i.teamId == i.chooserId
              ? '${team(i.chooserId)} : ${mod(i.catalogId)} (M${i.round})'
              : '${team(i.chooserId)} : ${mod(i.catalogId)} contre '
                  '${team(i.teamId)} (M${i.round})'),
    ));
  }

  if (of(RecapKind.boost).isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Coup de pouce de l\'app',
      detail: joined(RecapKind.boost, (i) {
        final bonus =
            modifierById(i.catalogId ?? '')?.nature == ModifierNature.bonus;
        return '${team(i.teamId)} ${bonus ? 'reçoit' : 'subit'} '
            '${mod(i.catalogId)} (M${i.round})';
      }),
    ));
  }

  if (of(RecapKind.bonusUsed).isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Cartouches utilisées',
      detail: joined(
          RecapKind.bonusUsed,
          (i) => i.chooserId == null
              ? '${mod(i.catalogId)}, ${team(i.teamId)} en M${i.round}'
              : '${mod(i.catalogId)}, ${team(i.chooserId)} contre '
                  '${team(i.teamId)} en M${i.round}'),
    ));
  }
  return lines;
}
