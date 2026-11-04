import 'fiesta_state.dart';
import 'modifier_catalog.dart';
import 'modifier_instance.dart';
import 'offers.dart';
import 'symmetric_draw.dart';
import 'turn_time.dart';

/// Passage de la manche N à N+1 (stories 2-5, 2-6, 2-10) : tout ce qu'il pose.
///
/// 🔴 UN seul plan, recalculé depuis l'état de fin de N (graine, scores,
/// choix persistés) : l'aperçu de la transition et l'application atomique de
/// `nextRound` le lisent tous deux, ils ne peuvent donc pas diverger. Le
/// retour arrière et l'app tuée retrouvent le même plan sans rien stocker.
class RoundTransitionPlan {
  /// Manche d'arrivée (N+1).
  final int round;

  /// Règles de manche de N+1 (« Toujours » + tirage), pour toutes les
  /// équipes.
  final List<ModifierInstance> draw;

  /// Cartouches « En stock » reçues par chaque équipe à l'entrée de N+1.
  final List<ModifierInstance> stock;

  /// Coup de pouce de l'app (Auto).
  final List<ModifierInstance> gifts;

  /// Cartes « 1 parmi 3 » choisies sur cette transition, dans l'ordre.
  final List<ModifierInstance> choices;

  /// Rattrapage dû à l'entrée de N+1, sur les scores de fin de N.
  final List<CatchUpEntry> catchUp;

  const RoundTransitionPlan({
    required this.round,
    required this.draw,
    this.stock = const [],
    required this.gifts,
    required this.choices,
    required this.catchUp,
  });

  /// L'état Fiesta d'entrée de N+1.
  ///
  /// Ce qui survit : les instances de N, et seulement elles. Elles servent à
  /// la continuation (même tour que la fin de N, `modifiersForTurn`) et
  /// partent à sa fin ; celles d'avant N partent ici. Celles de N+1 arrivent,
  /// mais ne s'appliquent qu'aux vrais tours de N+1.
  FiestaState apply(FiestaState fiesta) => fiesta.copyWith(
        active: [
          ...fiesta.active.where((m) => m.round >= round - 1),
          ...draw,
          ...stock,
          ...gifts,
          ...choices,
        ],
        catchUpDue: {for (final e in catchUp) e.teamId: e.seconds},
      );
}

/// Plan du passage après la manche [finishedRound], sur les [scores] de fin de
/// manche. `null` après M3 (on va aux résultats).
RoundTransitionPlan? planRoundTransition({
  required FiestaState fiesta,
  required String gameId,
  required int finishedRound,
  required Map<String, int> scores,
}) {
  if (finishedRound >= 3) return null;
  final rules = fiesta.rules;
  final round = finishedRound + 1;
  final draw = roundModifiers(rules, gameId: gameId, round: round);
  final catchUpRules = effectiveCatchUp(rules);
  return RoundTransitionPlan(
    round: round,
    draw: draw,
    stock: stockForRound(rules,
        round: round, teamIds: scores.keys, chargesUsed: fiesta.chargesUsed),
    gifts: isAppBoostOn(rules, finishedRound)
        ? appBoost(
            rules: rules,
            gameId: gameId,
            round: finishedRound,
            standings: Standings(scores),
            roundDraw: draw,
          )
        : const [],
    choices: [
      for (final c in fiesta.offerChoices)
        if (c.modifier.round == round) c.modifier,
    ],
    catchUp: catchUpRules == null
        ? const []
        : computeCatchUp(
            rules: catchUpRules, round: finishedRound, scores: scores),
  );
}

/// Instances qui pèsent sur [teamId] pendant son tour : celles de la manche
/// LOGIQUE du tour. Une continuation (temps reporté en début de N+1) est le
/// même tour que la fin de N : elle joue avec les effets de N, jamais ceux de
/// N+1, qui commencent au premier vrai tour de chaque équipe.
List<ModifierInstance> modifiersForTurn(
  List<ModifierInstance> active, {
  required String teamId,
  required int logicalRound,
}) =>
    active
        .where((m) =>
            m.round == logicalRound &&
            (m.target == ModifierTarget.both || m.teamId == teamId))
        .toList();
