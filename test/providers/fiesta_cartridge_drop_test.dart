import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/cartridge_drop.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/word_event.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import 'zero_carryover_turn_test.dart' show givenGame, validate;

/// Cartouches qui tombent, branchées en partie (D4 des retours du 2026-11-15).
void main() {
  final often = FiestaRules(dropFrequency: DropFrequency.often);

  CartridgeDrop? drawn(String gameId, List<String> team,
          {int giver = 0, int skips = 0, int gap = 0}) =>
      dropForTurn(
        rules: often,
        gameId: gameId,
        turnIndex: 0,
        giverId: team[giver],
        skips: skips,
        round: 1,
        roundRules: const [],
        received: const [],
        armed: const [],
        guesserIds: [...team]..removeAt(giver),
        gap: gap,
        continuation: false,
      );

  /// Partie à 2 équipes de 3, dont le 1er tour (J0 de l'équipe 0) voit tomber
  /// [id] : on cherche une graine qui le donne ([accept] en plus), puis on la
  /// pose comme `gameId`. [rivalScore] : score de l'équipe 1 (écart du ×2).
  Future<GameProvider> givenDrop(String id,
      {int rivalScore = 0,
      bool Function(String gameId, List<String> team)? accept}) async {
    final p = await givenGame(2, fiesta: often);
    final team = p.teams[0].playerIds;
    var i = 0;
    while (drawn('g$i', team, gap: rivalScore)?.catalogId != id ||
        !(accept?.call('g$i', team) ?? true)) {
      i++;
    }
    p.goToScreen(AppConstants.screenVerification);
    p.savePreValidationState(const []);
    p.game.preValidationSnapshot!['game'] = p.game.toJson()
      ..remove('preValidationSnapshot')
      ..['gameId'] = 'g$i'
      ..['currentScreen'] = AppConstants.screenGame;
    (p.game.preValidationSnapshot!['teamScores'] as List)[1]['score'] =
        rivalScore;
    p.restorePreValidationState();
    p.goToScreen(AppConstants.screenGame);
    return p;
  }

  int allotted(GameProvider p) =>
      (p.game.turnEndTimestamp! - p.game.turnStartTimestamp!) ~/ 1000;

  test(
      'la cartouche tombée est gardée dans le tour : une app tuée la retrouve, '
      'elle pèse sur le chrono et part à la vraie fin du tour', () async {
    final p = await givenDrop('minus_10s');
    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenTurnReveal,
        reason: 'une cartouche tombée suffit à « Ce qui t\'attend »');
    expect(p.droppedThisTurn?.catalogId, 'minus_10s');

    await pumpEventQueue();
    final relu = GameProvider();
    await pumpEventQueue();
    expect(relu.game.currentScreen, AppConstants.screenTurnReveal);
    expect(relu.droppedThisTurn?.catalogId, 'minus_10s');
    expect(relu.receivedThisTurn, isEmpty);
    expect(relu.roundRulesThisTurn, isEmpty);

    relu.leaveTurnReveal();
    relu.startTurnTimer();
    expect(allotted(relu), relu.settings.turnDuration - 10);
    relu.endTurn();
    validate(relu, const []);
    expect(relu.game.fiesta!.turn.drop, isNull);
  });

  test(
      'un ×2 tombé double les points du tour, sans rien prendre au stock ; '
      'l\'analytics le porte une fois', () async {
    final p = await givenDrop('double_points', rivalScore: 20);
    final team = p.teams[0];
    p.startTurn();
    p.leaveTurnReveal();
    p.startTurnTimer();
    p.markWordAsGuessed();
    p.markWordAsGuessed();
    final guessed = AnalyticsService()
        .currentGame!
        .events
        .lastWhere((e) => e.eventType == WordEventType.guessed);
    expect(guessed.modifiers, ['double_points']);
    p.endTurn();
    validate(p, List<String>.from(p.game.wordsGuessedThisTurn));

    expect(p.teams[0].score, 4);
    expect(p.game.fiesta!.chargesUsed, isEmpty);
    expect(p.game.fiesta!.cartridgesLeft('double_points', team.id), 0);
  });

  test(
      '« Interdit de faire deviner » tombé : décompte puis piège, sans « Ce '
      'qui t\'attend » ; le remplaçant a son propre tirage', () async {
    // Le remplaçant ne retombe pas sur le piège, et son tirage dépend des
    // tours sautés de l'équipe.
    final p = await givenDrop('block_giver', accept: (g, team) {
      final next = drawn(g, team, giver: 1, skips: 1)?.catalogId;
      return next != 'block_giver' &&
          next != drawn(g, team, giver: 1)?.catalogId;
    });
    final team = p.teams[0];
    final expected = drawn(p.game.gameId!, team.playerIds, giver: 1, skips: 1);

    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenCountdown);
    p.startTurnTimer();
    expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
    expect(p.giverBlockScreen!.phrase, contains('tombée du ciel'));
    p.confirmGiverBlock();

    expect(p.game.currentScreen, AppConstants.screenGame);
    expect(p.getCurrentPlayer()!.id, team.playerIds[1]);
    expect(p.game.fiesta!.skips[team.id], 1);
    expect(p.game.fiesta!.turn.drop, isNull);
    p.startTurn();
    expect(p.game.fiesta!.turn.drop?.catalogId, expected?.catalogId);
    expect(
        p.game.fiesta!.turn.drop?.blockedPlayerId, expected?.blockedPlayerId);
  });

  test('le malus tombé entre dans `WordEvent.modifiers`, une fois', () async {
    final p = await givenDrop('reversed');
    p.startTurn();
    p.leaveTurnReveal();
    p.startTurnTimer();
    expect(p.isWordReversed, isTrue);
    final shown = AnalyticsService()
        .currentGame!
        .events
        .lastWhere((e) => e.eventType == WordEventType.shown);
    expect(shown.modifiers, ['reversed']);
  });
}
