import 'dart:math';

import 'fiesta_rules.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';

/// Cartouches au hasard (Fiesta v4) : « À tous, à chaque manche », « Aux équipes
/// menées », « Équilibrer la partie ». Tout est pur et DÉTERMINISTE par
/// `(gameId, manche, équipe)` : une app tuée, un retour arrière ou une
/// correction retrouvent le même cadeau (voir [drawSeed]).
///
/// Vocabulaire : `finishedRound` = la manche N qui vient de finir, 0 au
/// lancement de la partie.

/// « Équilibrer la partie » : seuils de l'écart avec le leader, rapporté au
/// nombre de mots de la partie. À recalibrer après des parties réelles.
const double kBalanceSmallGap = 0.10;
const double kBalanceLargeGap = 0.25;

/// Cartouches de « Équilibrer la partie » pour un écart de [gap] points avec le
/// leader : moins de 10 % des mots = 1, de 10 à 25 % = 2, plus de 25 % = 3. Rien
/// sans écart.
int balanceGiftCount({required int gap, required int totalWords}) {
  if (gap <= 0) return 0;
  final share = gap / max(totalWords, 1);
  if (share < kBalanceSmallGap) return 1;
  return share <= kBalanceLargeGap ? 2 : 3;
}

/// Graine d'une équipe : `(gameId, manche, équipe)`. Réutilise le FNV-1a de
/// [drawSeed] (chaîne `gameId#teamId#round`, distincte de celle du tirage).
int giftSeed(String gameId, int round, String teamId) =>
    drawSeed('$gameId#$teamId', round);

/// Vivier du hasard de [teamId], dans l'ordre du catalogue (le tirage doit
/// partir de la même liste) : tout ce qui peut être cartouche, hors « Toujours »
/// ; les compteurs n'interviennent pas. Filtres : possible en manche [nextRound],
/// ni déjà en jeu ni incompatible avec les règles de cette manche ([roundRules]),
/// et « Bloquer un devineur » seulement si une AUTRE équipe peut le recevoir
/// ([blockableTeamIds] : au moins 3 joueurs).
List<ModifierDef> giftPool({
  required FiestaRules rules,
  required int nextRound,
  required List<ModifierInstance> roundRules,
  required String teamId,
  required Set<String> blockableTeamIds,
}) =>
    [
      for (final def in kModifierCatalog)
        if (!rules.isAlways(def.id) &&
            isEligibleForRound(def, nextRound) &&
            roundRules.every((r) =>
                r.catalogId != def.id && areCompatible(r.catalogId, def.id)) &&
            (def.id != 'block_guesser' ||
                blockableTeamIds.any((id) => id != teamId)))
          def,
    ];

/// Combien de cartouches au hasard pour [teamId] après [finishedRound] :
/// `allCount` à chaque manche, plus, après M1 et M2, selon l'écart avec le
/// leader (`balance`) ou `trailingCount` pour une équipe non en tête. Égalité
/// générale ou co-leaders : rien de ce second terme.
int giftCount(
  FiestaRules rules, {
  required int finishedRound,
  required int gap,
  required int totalWords,
}) {
  if (finishedRound < 1) return rules.allCount;
  final trailing = rules.balance
      ? balanceGiftCount(gap: gap, totalWords: totalWords)
      : (gap > 0 ? rules.trailingCount : 0);
  return rules.allCount + trailing;
}

/// Cartouches gagnées au début de la manche `finishedRound + 1`, équipe par
/// équipe dans l'ordre de [scores]. Le vivier est mélangé par la graine de
/// l'équipe puis pris dans l'ordre : DISTINCTES tant que le vivier le permet,
/// puis il repart du début. Vivier vide : rien. Le tirage d'une équipe ne dépend
/// pas des autres ni, à nombre égal, du score.
List<EarnedCartridge> roundGifts({
  required FiestaRules rules,
  required String gameId,
  required int finishedRound,
  required Map<String, int> scores,
  required int totalWords,
  required List<ModifierInstance> roundRules,
  required Set<String> blockableTeamIds,
}) {
  final next = finishedRound + 1;
  final top = scores.values.fold<int>(0, max);
  return [
    for (final MapEntry(key: teamId, value: score) in scores.entries)
      ..._giftsOf(
        teamId: teamId,
        round: next,
        count: giftCount(rules,
            finishedRound: finishedRound,
            gap: top - score,
            totalWords: totalWords),
        pool: giftPool(
          rules: rules,
          nextRound: next,
          roundRules: roundRules,
          teamId: teamId,
          blockableTeamIds: blockableTeamIds,
        )..shuffle(Random(giftSeed(gameId, finishedRound, teamId))),
      ),
  ];
}

Iterable<EarnedCartridge> _giftsOf({
  required String teamId,
  required int round,
  required int count,
  required List<ModifierDef> pool,
}) sync* {
  if (pool.isEmpty) return;
  for (var i = 0; i < count; i++) {
    yield EarnedCartridge(
      catalogId: pool[i % pool.length].id,
      teamId: teamId,
      round: round,
    );
  }
}
