import 'dart:math';

import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';

/// « 1 parmi 3 » (Personnalisé) et « Coup de pouce de l'app » (Auto), story
/// 2-10. Tout est pur et DÉTERMINISTE par `(gameId, manche, équipe)` : une app
/// tuée ou un retour arrière retrouvent les mêmes offres (voir [drawSeed]).
///
/// Vocabulaire : [round] = la manche N qui vient de finir ; les effets portent
/// sur toute la manche N+1 (Q7).

enum OfferStrength { light, medium, heavy }

/// 🔴 À RECALIBRER : table « au doigt mouillé » (Q7). Un id absent n'est
/// jamais proposé.
const Map<String, OfferStrength> kOfferStrength = {
  'free_pass': OfferStrength.light,
  'minus_10s': OfferStrength.light,
  'reversed': OfferStrength.light,
  'mime_no_fists': OfferStrength.light,
  'double_points': OfferStrength.medium,
  'two_words': OfferStrength.medium,
  'no_pass': OfferStrength.medium,
  'draw': OfferStrength.medium,
  'block_guesser': OfferStrength.heavy,
  'mime_no_arms': OfferStrength.heavy,
  'mime_eyes_closed': OfferStrength.heavy,
};

/// 🔴 À RECALIBRER : seuils de la maquette, écart ≤ 3 → légère, ≤ 7 →
/// moyenne, au-delà → forte.
OfferStrength strengthForGap(int gap) => gap <= 3
    ? OfferStrength.light
    : gap <= 7
        ? OfferStrength.medium
        : OfferStrength.heavy;

String strengthLabel(OfferStrength s) => switch (s) {
      OfferStrength.light => 'légère',
      OfferStrength.medium => 'moyenne',
      OfferStrength.heavy => 'forte',
    };

/// Nombre d'offres montrées à une équipe qui choisit.
const int kOfferCount = 3;

/// Classement de fin de manche, même lecture que `computeCatchUp` (2-6).
class Standings {
  /// Score par id d'équipe, dans l'ordre des équipes.
  final Map<String, int> scores;

  const Standings(this.scores);

  int get _top => scores.values.reduce(max);

  /// Égalité générale (Q3) : ni 1 parmi 3, ni coup de pouce.
  bool get isTie => scores.length < 2 || scores.values.every((s) => s == _top);

  /// Équipes en tête (plusieurs = co-leaders).
  List<String> get leaderIds => isTie
      ? const []
      : [
          for (final e in scores.entries)
            if (e.value == _top) e.key
        ];

  /// LA cible d'un malus : l'équipe en tête, `null` si égalité ou co-leaders
  /// (pas de cible unique, donc aucun malus proposé ni donné).
  String? get leaderId => leaderIds.length == 1 ? leaderIds.single : null;

  /// Écart avec la tête pour une équipe menée ; avec la 2ᵉ pour le leader.
  int gapOf(String teamId) {
    final score = scores[teamId]!;
    if (score < _top) return _top - score;
    final others = scores.values.where((s) => s < _top);
    return others.isEmpty ? 0 : _top - others.reduce(max);
  }

  /// Ordre de choix : les équipes NON en tête, de la dernière à la meilleure.
  /// À score égal, l'ordre des équipes (tri stable). Vide en cas d'égalité.
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

/// Le 1 parmi 3 a-t-il lieu après la manche [round] ? (Personnalisé, `pick3`
/// allumé, après M1 ou M2 seulement : après M3 on va aux résultats.)
bool isPickThreeOn(FiestaRules rules, int round) =>
    rules.mode == FiestaMode.custom && rules.oneOfThree && round < 3;

/// Le coup de pouce de l'app a-t-il lieu après la manche [round] ? (Auto,
/// « Auto-calibrage » allumé, après M1 ou M2.)
bool isAppBoostOn(FiestaRules rules, int round) =>
    rules.mode == FiestaMode.auto && rules.autoCalibrate && round < 3;

/// Graine d'une équipe : `(gameId, manche, équipe)`. Réutilise le FNV-1a de
/// [drawSeed] (chaîne `gameId#teamId#round`, distincte de celle du tirage).
int offerSeed(String gameId, int round, String teamId) =>
    drawSeed('$gameId#$teamId', round);

/// Candidats d'une [nature] à la [strength] voulue pour la manche [round]+1,
/// dans l'ordre du catalogue (le mélange doit partir de la même liste).
///
/// Un bonus vise [beneficiaryId], un malus vise [leaderId] (aucun malus si
/// `null`). Personnalisé : seuls les modificateurs actifs réglés sur
/// « proposé à l'équipe menée » et dont la manche de départ est atteinte.
/// « Bloquer un devineur » : jamais en Auto (personne ne choisit, donc
/// personne ne désigne le devineur) ; en Personnalisé, jamais contre une
/// équipe de [blockImmuneTeamIds].
List<ModifierInstance> _candidates({
  required FiestaRules rules,
  required int round,
  required OfferStrength strength,
  required Set<ModifierNature> natures,
  required String beneficiaryId,
  required String? leaderId,
  required Set<String> blockImmuneTeamIds,
}) {
  final next = round + 1;
  final custom = rules.mode == FiestaMode.custom;
  final out = <ModifierInstance>[];
  for (final def in kModifierCatalog) {
    if (!natures.contains(def.nature) ||
        kOfferStrength[def.id] != strength ||
        !isEligibleForRound(def, next)) {
      continue;
    }
    var charges = def.defaultCharges;
    if (custom) {
      final setting = rules.modifiers[def.id];
      if (setting == null ||
          !setting.active ||
          setting.arrival != ModifierArrival.offer ||
          setting.startRound > next) {
        continue;
      }
      charges = setting.charges;
    }
    final targetTeam =
        def.nature == ModifierNature.bonus ? beneficiaryId : leaderId;
    if (targetTeam == null) continue;
    final toPlayer = def.defaultTarget == ModifierTarget.player;
    if (toPlayer && (!custom || blockImmuneTeamIds.contains(targetTeam))) {
      continue;
    }
    out.add(ModifierInstance(
      catalogId: def.id,
      scope: ModifierScope.round,
      target: toPlayer ? ModifierTarget.player : ModifierTarget.team,
      teamId: targetTeam,
      charges: charges,
      nature: def.nature,
      round: next,
    ));
  }
  return out;
}

/// Une carte a-t-elle un effet ? Non si elle est incompatible ou dépasse le
/// plafond de 2 pour sa cible (Q8), ni si le même modificateur touche déjà
/// sa cible (tirage, choix ou cadeau précédent : la carte serait vide).
bool _useful(List<ModifierInstance> taken, ModifierInstance c) =>
    canAdd(taken, c) &&
    !taken.any((t) => t.catalogId == c.catalogId && t.concernsSameTeamAs(c));

/// Jusqu'à [count] cartes utiles (voir [_useful]) à la force de [gap],
/// mélangées par la graine de [teamId]. Si cette force n'en a AUCUNE, on
/// descend d'un cran (forte → moyenne → légère) ; vide seulement si tous les
/// crans le sont.
List<ModifierInstance> _offer({
  required FiestaRules rules,
  required String gameId,
  required int round,
  required String teamId,
  required int gap,
  required Set<ModifierNature> natures,
  required String? leaderId,
  required Set<String> blockImmuneTeamIds,
  required List<ModifierInstance> taken,
  required int count,
}) {
  final random = Random(offerSeed(gameId, round, teamId));
  for (var s = strengthForGap(gap).index; s >= 0; s--) {
    final candidates = _candidates(
      rules: rules,
      round: round,
      strength: OfferStrength.values[s],
      natures: natures,
      beneficiaryId: teamId,
      leaderId: leaderId,
      blockImmuneTeamIds: blockImmuneTeamIds,
    )..shuffle(random);
    final picked =
        candidates.where((c) => _useful(taken, c)).take(count).toList();
    if (picked.isNotEmpty) return picked;
  }
  return const [];
}

/// Les offres (jusqu'à 3) montrées à [teamId] après la manche [round].
/// Liste vide = l'équipe est sautée.
///
/// - [roundDraw] = le tirage de la manche N+1 (`roundModifiers`).
/// - [choices] = les choix déjà faits, par id de l'équipe QUI a choisi (un
///   malus choisi vise le leader : sans cette clé, on ne saurait plus qui l'a
///   choisi, ni qui désigne le devineur de « Bloquer un devineur »).
/// - [blockImmuneTeamIds] : équipes qui ne peuvent pas recevoir « Bloquer un
///   devineur » (2 joueurs ou moins).
///
/// Prochaine équipe de la file = la première de [Standings.choosingOrder]
/// absente de [choices] dont les offres ne sont pas vides.
List<ModifierInstance> pickThreeOffers({
  required FiestaRules rules,
  required String gameId,
  required int round,
  required Standings standings,
  required String teamId,
  required List<ModifierInstance> roundDraw,
  Map<String, ModifierInstance> choices = const {},
  Set<String> blockImmuneTeamIds = const {},
}) {
  if (!standings.choosingOrder.contains(teamId)) return const [];
  return _offer(
    rules: rules,
    gameId: gameId,
    round: round,
    teamId: teamId,
    gap: standings.gapOf(teamId),
    natures: ModifierNature.values.toSet(),
    leaderId: standings.leaderId,
    blockImmuneTeamIds: blockImmuneTeamIds,
    taken: [...roundDraw, ...choices.values],
    count: kOfferCount,
  );
}

/// Coup de pouce de l'app (Auto) après la manche [round] : au plus un bonus
/// par équipe menée (dans l'ordre de [Standings.choosingOrder]), puis au plus
/// un malus pour l'équipe en tête, chacun à la force de l'écart de l'équipe
/// concernée (un cran plus bas si elle est vide). Mêmes exclusions que le
/// 1 parmi 3, vis-à-vis de [roundDraw] (le tirage de N+1) et des cadeaux déjà
/// faits. Jamais de « Bloquer un devineur ».
List<ModifierInstance> appBoost({
  required FiestaRules rules,
  required String gameId,
  required int round,
  required Standings standings,
  required List<ModifierInstance> roundDraw,
}) {
  final gifts = <ModifierInstance>[];
  final leaderId = standings.leaderId;
  void give(String teamId, ModifierNature nature) {
    gifts.addAll(_offer(
      rules: rules,
      gameId: gameId,
      round: round,
      teamId: teamId,
      gap: standings.gapOf(teamId),
      natures: {nature},
      leaderId: leaderId,
      blockImmuneTeamIds: const {},
      taken: [...roundDraw, ...gifts],
      count: 1,
    ));
  }

  for (final teamId in standings.choosingOrder) {
    give(teamId, ModifierNature.bonus);
  }
  if (leaderId != null) give(leaderId, ModifierNature.malus);
  return gifts;
}
