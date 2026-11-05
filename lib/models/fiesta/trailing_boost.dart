import 'dart:math';

import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';

/// Coup de pouce à l'équipe menée (Fiesta v3). Tout est pur et DÉTERMINISTE
/// par `(gameId, manche, équipe)` : une app tuée ou un retour arrière
/// retrouvent le même cadeau (voir [drawSeed]).
///
/// Vocabulaire : `finishedRound` = la manche N qui vient de finir.

/// Classement de fin de manche.
class Standings {
  /// Score par id d'équipe, dans l'ordre des équipes.
  final Map<String, int> scores;

  const Standings(this.scores);

  int get _top => scores.values.reduce(max);

  /// Égalité générale : personne n'est mené.
  bool get isTie => scores.length < 2 || scores.values.every((s) => s == _top);

  /// Les équipes NON en tête (co-leaders exclus), de la dernière à la
  /// meilleure ; à score égal, l'ordre des équipes (tri stable). Vide en cas
  /// d'égalité générale.
  List<String> get choosingOrder {
    if (isTie) return const [];
    final top = _top;
    final trailing = scores.entries.where((e) => e.value < top).toList();
    final indexed = trailing.indexed.toList()
      ..sort((a, b) {
        final byScore = a.$2.value.compareTo(b.$2.value);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    return [for (final (_, e) in indexed) e.key];
  }
}

/// Graine d'une équipe : `(gameId, manche, équipe)`. Réutilise le FNV-1a de
/// [drawSeed] (chaîne `gameId#teamId#round`, distincte de celle du tirage).
int boostSeed(String gameId, int round, String teamId) =>
    drawSeed('$gameId#$teamId', round);

/// Vivier du coup de pouce de [teamId], dans l'ordre du catalogue (le tirage
/// doit partir de la même liste) : Personnalisé, les modificateurs actifs en
/// Cartouche ; Auto, tout ce qui peut être cartouche. Filtres : possible en
/// manche [nextRound], ni déjà en jeu ni incompatible avec les règles de cette
/// manche ([roundRules]), et « Bloquer un devineur » seulement si une AUTRE
/// équipe peut le recevoir ([blockableTeamIds] : au moins 3 joueurs).
List<ModifierDef> boostPool({
  required FiestaRules rules,
  required int nextRound,
  required List<ModifierInstance> roundRules,
  required String teamId,
  required Set<String> blockableTeamIds,
}) =>
    [
      for (final def in kModifierCatalog)
        if (canBeCartridge(def) &&
            (rules.mode == FiestaMode.auto ||
                rules.activeSetting(def.id)?.mode == ModifierMode.cartridge) &&
            isEligibleForRound(def, nextRound) &&
            roundRules.every((r) =>
                r.catalogId != def.id && areCompatible(r.catalogId, def.id)) &&
            (def.defaultTarget != ModifierTarget.player ||
                blockableTeamIds.any((id) => id != teamId)))
          def,
    ];

/// Cartouches gagnées après la manche [finishedRound] : exactement UNE au
/// hasard par équipe non en tête, si `rules.trailingBoost`. Égalité générale
/// ou vivier vide : rien. Le tirage d'une équipe ne dépend pas des autres.
List<EarnedCartridge> trailingBoostGifts({
  required FiestaRules rules,
  required String gameId,
  required int finishedRound,
  required Standings standings,
  required List<ModifierInstance> roundRules,
  required Set<String> blockableTeamIds,
}) {
  if (!rules.trailingBoost) return const [];
  final next = finishedRound + 1;
  return [
    for (final teamId in standings.choosingOrder)
      if (boostPool(
        rules: rules,
        nextRound: next,
        roundRules: roundRules,
        teamId: teamId,
        blockableTeamIds: blockableTeamIds,
      )
          case final pool when pool.isNotEmpty)
        EarnedCartridge(
          catalogId: pool[Random(boostSeed(gameId, finishedRound, teamId))
                  .nextInt(pool.length)]
              .id,
          teamId: teamId,
          round: next,
        ),
  ];
}
