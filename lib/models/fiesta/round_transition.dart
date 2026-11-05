import 'cartridge_gifts.dart';
import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'symmetric_draw.dart';

/// Passage de la manche N à N+1 : tout ce qu'il pose.
///
/// 🔴 Plan recalculé depuis l'état de fin de N (graine, scores) : la transition
/// ne persiste rien, `nextRound` l'applique une seule fois. Le retour arrière
/// (qui restaure l'état d'avant) et l'app tuée retrouvent le même plan, sans
/// doubler ni perdre de cartouche.
class RoundTransitionPlan {
  /// Manche d'arrivée (N+1).
  final int round;

  /// Règles de manche de N+1 (« Toujours » + tirage), pour toutes les
  /// équipes.
  final List<ModifierInstance> draw;

  /// Cartouches au hasard du début de N+1.
  final List<EarnedCartridge> gifts;

  /// Équipe qui poursuit son tour en N+1 : ses malus reçus sont déjà appliqués,
  /// ils ne se rendent pas.
  final String? continuingTeamId;

  const RoundTransitionPlan({
    required this.round,
    required this.draw,
    this.gifts = const [],
    this.continuingTeamId,
  });

  /// L'état Fiesta d'entrée de N+1.
  ///
  /// Les règles de N partent : celles de N+1 s'appliquent tout de suite, y
  /// compris à la continuation. Seul un malus infligé survit : il attend le
  /// prochain tour de sa cible, quelle que soit la manche. S'il y devient
  /// impossible ([crossesRules]), sa cartouche est RENDUE à l'envoyeur. Le malus
  /// déjà en cours sur le tour qui continue n'est pas rendu : il tombe seul
  /// ([modifiersForTurn]).
  FiestaState apply(FiestaState fiesta) {
    var next = fiesta.copyWith(
      active: [
        ...fiesta.active.where((m) => m.fromTeamId != null),
        ...draw,
      ],
      earned: [...fiesta.earned, ...gifts],
    );
    for (final m in fiesta.active) {
      if (m.fromTeamId != null &&
          m.teamId != continuingTeamId &&
          crossesRules(m, rules: draw, round: round)) {
        next = next.withoutSent(m);
      }
    }
    return next;
  }
}

/// Le malus infligé [malus] ne peut pas jouer sous les règles [rules] de la
/// manche [round] : interdit dans la manche, identique ou incompatible.
bool crossesRules(
  ModifierInstance malus, {
  required List<ModifierInstance> rules,
  required int round,
}) =>
    !isEligibleForRound(modifierById(malus.catalogId)!, round) ||
    rules.any((r) =>
        r.catalogId == malus.catalogId ||
        !areCompatible(r.catalogId, malus.catalogId));

/// Plan du passage après la manche [finishedRound], sur les [scores] de fin de
/// manche. `null` après M3 (on va aux résultats). [blockableTeamIds] : équipes
/// d'au moins 3 joueurs (`roundGifts`).
RoundTransitionPlan? planRoundTransition({
  required FiestaState fiesta,
  required String gameId,
  required int finishedRound,
  required Map<String, int> scores,
  required int totalWords,
  required Set<String> blockableTeamIds,
  String? continuingTeamId,
}) {
  if (finishedRound >= 3) return null;
  final round = finishedRound + 1;
  final draw = roundModifiers(fiesta.rules, gameId: gameId, round: round);
  return RoundTransitionPlan(
    round: round,
    draw: draw,
    continuingTeamId: continuingTeamId,
    gifts: roundGifts(
      rules: fiesta.rules,
      gameId: gameId,
      finishedRound: finishedRound,
      scores: scores,
      totalWords: totalWords,
      roundRules: draw,
      blockableTeamIds: blockableTeamIds,
    ),
  );
}

/// Instances qui pèsent sur [teamId] pendant le tour de [playerId] : les règles
/// de la manche [round] (la manche COURANTE, y compris pour une continuation :
/// les règles de N+1 s'appliquent directement au temps reporté).
///
/// 🔴 Malus infligés ([ModifierInstance.fromTeamId]) : SEULE résolution, au
/// tour de la cible (quelle que soit la manche d'envoi). Un malus interdit
/// dans la manche, déjà en jeu (même id) ou incompatible avec une règle de
/// manche ou un malus déjà retenu pour ce tour est écarté : sans effet. En
/// continuation, un malus reçu est jugé contre la manche courante : « Autre
/// langue » reçu en M2 tombe en M3, où on mime.
///
/// Les blocages qui attendent sont écartés ([ModifierInstance.waitsFor]).
List<ModifierInstance> modifiersForTurn(
  List<ModifierInstance> active, {
  required String teamId,
  required String? playerId,
  required int round,
}) {
  final rules =
      active.where((m) => m.fromTeamId == null && m.round == round).toList();
  // Règles de manche et malus déjà retenus : ce contre quoi un malus reçu se
  // juge.
  final weighing = [...rules];
  final received = <ModifierInstance>{};
  for (final m in active) {
    if (m.fromTeamId == null || m.teamId != teamId) continue;
    if (m.waitsFor(playerId) ||
        !isEligibleForRound(modifierById(m.catalogId)!, round) ||
        weighing.any((w) => w.catalogId == m.catalogId) ||
        !weighing.every((w) => areCompatible(w.catalogId, m.catalogId))) {
      continue;
    }
    weighing.add(m);
    received.add(m);
  }
  return [
    for (final m in active)
      if (rules.contains(m) || received.contains(m)) m,
  ];
}
