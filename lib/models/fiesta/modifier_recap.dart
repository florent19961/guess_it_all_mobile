import '../../utils/constants.dart';
import '../game_result.dart';
import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
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
/// manche) : c'est ce qui est archivé, le texte est formé à l'affichage par
/// [formatModifierRecap]. Le tirage est recalculé par la graine `(gameId,
/// manche)`, le reste relu de l'état : coup de pouce ([earned]) et cartouches
/// utilisées ([chargesUsed]).
List<ModifierRecapItem> buildModifierRecap({
  required FiestaRules rules,
  required String gameId,
  required int roundsPlayed,
  List<ChargeUse> chargesUsed = const [],
  List<EarnedCartridge> earned = const [],
}) =>
    [
      for (var round = 1; round <= roundsPlayed; round++)
        for (final m in roundModifiers(rules, gameId: gameId, round: round))
          ModifierRecapItem(RecapKind.draw,
              round: round, catalogId: m.catalogId),
      for (final e in earned)
        ModifierRecapItem(RecapKind.boost,
            round: e.round, catalogId: e.catalogId, teamId: e.teamId),
      // Un malus infligé : `chooserId` = qui l'a joué, `teamId` = sa cible.
      for (final u in chargesUsed)
        ModifierRecapItem(RecapKind.bonusUsed,
            round: u.round,
            catalogId: u.catalogId,
            teamId: u.targetTeamId ?? u.teamId,
            chooserId: u.targetTeamId == null ? null : u.teamId),
    ];

/// Lignes affichées du récap, depuis ses faits. [teamNames] : id → nom.
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

  if (of(RecapKind.boost).isNotEmpty) {
    lines.add(ModifierRecapLine(
      title: 'Coup de pouce à l\'équipe menée',
      detail: joined(RecapKind.boost,
          (i) => '${team(i.teamId)} reçoit ${mod(i.catalogId)} (M${i.round})'),
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
