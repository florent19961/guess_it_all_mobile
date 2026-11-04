import 'dart:math';

import 'fiesta_rules.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';
import 'turn_effects.dart';

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
  'mime_back_turned': OfferStrength.medium,
  'other_language': OfferStrength.medium,
  'mime_under_sheet': OfferStrength.heavy,
  'one_answer': OfferStrength.medium,
  'sounds_only': OfferStrength.medium,
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

/// Le 1 parmi 3 a-t-il lieu après la manche [round] ? (Personnalisé, au moins
/// un modificateur « 1 parmi 3 » coché sur la manche suivante, après M1 ou M2
/// seulement : après M3 on va aux résultats.)
bool isPickThreeOn(FiestaRules rules, int round) =>
    rules.mode == FiestaMode.custom &&
    round < 3 &&
    rules.modifiers.values.any((s) =>
        s.active &&
        s.mode == ModifierMode.offer &&
        s.rounds.contains(round + 1));

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
/// Une carte est UNE cartouche de [beneficiaryId] (Fiesta v2, lane 2) : un
/// bonus pour elle, ou un malus qui entre dans sa réserve, à infliger à
/// l'équipe de son choix. Personnalisé : seuls les modificateurs actifs en
/// « 1 parmi 3 » cochés sur la manche [round]+1.
///
/// Auto (coup de pouce, personne ne choisit) : un malus frappe [leaderId]
/// toute la manche N+1 (aucun si `null`), et jamais « Bloquer un devineur »
/// (personne pour désigner le devineur). En Personnalisé, « Bloquer un
/// devineur » seulement si [canBlock] (une équipe adverse d'au moins 3
/// joueurs).
List<ModifierInstance> _candidates({
  required FiestaRules rules,
  required int round,
  required OfferStrength strength,
  required Set<ModifierNature> natures,
  required String beneficiaryId,
  required String? leaderId,
  required bool canBlock,
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
    if (custom) {
      final setting = rules.activeSetting(def.id);
      if (setting == null ||
          setting.mode != ModifierMode.offer ||
          !setting.rounds.contains(next)) {
        continue;
      }
    }
    final malus = def.nature == ModifierNature.malus;
    // Personnalisé : malus en réserve de celui qui choisit.
    final reserve = custom && malus;
    final targetTeam = malus && !custom ? leaderId : beneficiaryId;
    if (targetTeam == null) continue;
    final toPlayer = def.defaultTarget == ModifierTarget.player;
    if (toPlayer && (!custom || !canBlock)) continue;
    out.add(ModifierInstance(
      catalogId: def.id,
      scope: def.defaultScope,
      target: toPlayer ? ModifierTarget.player : ModifierTarget.team,
      teamId: targetTeam,
      // Une cartouche (bonus à charge ou malus en réserve) ; le malus du
      // coup de pouce garde l'effet de manche du catalogue.
      charges: reserve || kChargeBonusKeys.containsKey(def.id)
          ? 1
          : def.defaultCharges,
      nature: def.nature,
      round: next,
      reserve: reserve,
    ));
  }
  return out;
}

/// Une carte a-t-elle un effet ? Non si elle est incompatible pour sa cible,
/// ni si le même modificateur touche déjà sa cible (tirage, choix ou cadeau
/// précédent : la carte serait vide). Pas de plafond (Fiesta v2).
///
/// Une cartouche de malus en réserve vise une équipe choisie plus tard :
/// seules les règles de manche (pour tous) la rendent inutile ; et une
/// réserve ne pèse sur personne, elle n'exclut aucune autre carte.
bool isUsefulOffer(List<ModifierInstance> taken, ModifierInstance c) {
  final weighing = [
    for (final t in taken)
      if (!t.reserve && (!c.reserve || t.target == ModifierTarget.both)) t,
  ];
  return canAdd(weighing, c) &&
      !weighing
          .any((t) => t.catalogId == c.catalogId && t.concernsSameTeamAs(c));
}

/// Jusqu'à [count] cartes utiles (voir [isUsefulOffer]) à la force de [gap],
/// mélangées par la graine [seed]. Si cette force n'en a AUCUNE, on descend
/// d'un cran (forte → moyenne → légère) ; vide seulement si tous les crans le
/// sont. [excludedIds] : modificateurs déjà montrés (rangées précédentes).
List<ModifierInstance> _offer({
  required FiestaRules rules,
  required int seed,
  required int round,
  required String teamId,
  required int gap,
  required Set<ModifierNature> natures,
  required String? leaderId,
  required bool canBlock,
  required List<ModifierInstance> taken,
  required int count,
  Set<String> excludedIds = const {},
}) {
  final random = Random(seed);
  for (var s = strengthForGap(gap).index; s >= 0; s--) {
    final candidates = _candidates(
      rules: rules,
      round: round,
      strength: OfferStrength.values[s],
      natures: natures,
      beneficiaryId: teamId,
      leaderId: leaderId,
      canBlock: canBlock,
    )..shuffle(random);
    final picked = candidates
        .where((c) =>
            !excludedIds.contains(c.catalogId) && isUsefulOffer(taken, c))
        .take(count)
        .toList();
    if (picked.isNotEmpty) return picked;
  }
  return const [];
}

/// Les rangées d'offres montrées à [teamId] après la manche [round] : jusqu'à
/// `rules.pick3Choices` rangées de 3 cartes au plus, sur le même écran ;
/// l'équipe prend une carte par rangée, les restes sont perdus. Liste vide =
/// l'équipe est sautée ; une rangée vide n'est pas rendue.
///
/// - [roundDraw] = les règles de la manche N+1 (`roundModifiers`).
/// - [earlierChoices] = les cartes prises par les équipes passées AVANT
///   [teamId] dans la file (jamais les siennes : ses rangées ne bougent pas
///   pendant qu'elle choisit, [isUsefulOffer] grise ce que ses propres choix
///   rendent inutile).
/// - [blockImmuneTeamIds] : équipes qui ne peuvent pas recevoir « Bloquer un
///   devineur » (2 joueurs ou moins) ; la carte n'est offerte que si une
///   autre équipe que [teamId] peut la recevoir.
///
/// Rangée 0 : graine `offerSeed(gameId, round, teamId)` (figée par test) ;
/// rangée k : `offerSeed(gameId, round, '$teamId#k')`. Une rangée ne reprend
/// aucun modificateur d'une rangée précédente.
List<List<ModifierInstance>> pickThreeOffers({
  required FiestaRules rules,
  required String gameId,
  required int round,
  required Standings standings,
  required String teamId,
  required List<ModifierInstance> roundDraw,
  List<ModifierInstance> earlierChoices = const [],
  Set<String> blockImmuneTeamIds = const {},
}) {
  if (!standings.choosingOrder.contains(teamId)) return const [];
  final canBlock = standings.scores.keys
      .any((id) => id != teamId && !blockImmuneTeamIds.contains(id));
  final rows = <List<ModifierInstance>>[];
  final shown = <String>{};
  for (var k = 0; k < rules.pick3Choices; k++) {
    final row = _offer(
      rules: rules,
      seed: offerSeed(gameId, round, k == 0 ? teamId : '$teamId#$k'),
      round: round,
      teamId: teamId,
      gap: standings.gapOf(teamId),
      natures: ModifierNature.values.toSet(),
      leaderId: standings.leaderId,
      canBlock: canBlock,
      taken: [...roundDraw, ...earlierChoices],
      count: kOfferCount,
      excludedIds: shown,
    );
    if (row.isEmpty) break;
    rows.add(row);
    shown.addAll(row.map((c) => c.catalogId));
  }
  return rows;
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
      seed: offerSeed(gameId, round, teamId),
      round: round,
      teamId: teamId,
      gap: standings.gapOf(teamId),
      natures: {nature},
      leaderId: leaderId,
      canBlock: false,
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
