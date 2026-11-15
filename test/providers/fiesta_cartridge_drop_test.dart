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
          {int giver = 0,
          int skips = 0,
          int gap = 0,
          List<String> received = const []}) =>
      dropForTurn(
        rules: often,
        gameId: gameId,
        turnIndex: 0,
        giverId: team[giver],
        skips: skips,
        round: 1,
        roundRules: const [],
        received: received,
        armed: const [],
        guesserIds: [...team]..removeAt(giver),
        gap: gap,
        continuation: false,
      );

  /// Partie à 2 équipes de 3, dont le 1er tour (J0 de l'équipe 0) voit tomber
  /// [id] : on cherche une graine qui le donne ([accept] en plus), puis on la
  /// pose comme `gameId`. [rivalScore] : score de l'équipe 1 (écart du ×2).
  /// [received] : malus que J0 a reçus de l'équipe 1, qui jouent à ce tour.
  Future<GameProvider> givenDrop(String id,
      {int rivalScore = 0,
      List<String> received = const [],
      bool Function(String gameId, List<String> team)? accept}) async {
    final p = await givenGame(2, fiesta: often);
    final team = p.teams[0].playerIds;
    var i = 0;
    while (drawn('g$i', team, gap: rivalScore, received: received)?.catalogId !=
            id ||
        !(accept?.call('g$i', team) ?? true)) {
      i++;
    }
    p.goToScreen(AppConstants.screenVerification);
    p.savePreValidationState(const []);
    final json = p.game.toJson()
      ..remove('preValidationSnapshot')
      ..['gameId'] = 'g$i'
      ..['currentScreen'] = AppConstants.screenGame;
    (json['fiesta'] as Map)['active'] = [
      for (final malus in received)
        {
          'catalogId': malus,
          'scope': 'turn',
          'target': 'player',
          'teamId': p.teams[0].id,
          'playerId': team[0],
          'charges': 1,
          'nature': 'malus',
          'round': 1,
          'from': p.teams[1].id,
        },
    ];
    p.game.preValidationSnapshot!['game'] = json;
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
      'un ×2 tombé double les points du tour, continuation comprise, sans '
      'rien prendre au stock ni retirer sur la continuation ; l\'analytics le '
      'porte une fois', () async {
    final p = await givenDrop('double_points', rivalScore: 20);
    final team = p.teams[0];
    final words = p.game.allWords.length;
    p.startTurn();
    p.leaveTurnReveal();
    p.startTurnTimer();
    p.markWordAsGuessed();
    final guessed = AnalyticsService()
        .currentGame!
        .events
        .lastWhere((e) => e.eventType == WordEventType.guessed);
    expect(guessed.modifiers, ['double_points']);
    // Toute la manche avant le chrono : la même équipe poursuit en M2.
    while (p.game.currentScreen == AppConstants.screenTurn) {
      p.markWordAsGuessed();
    }
    validate(p, List<String>.from(p.game.wordsGuessedThisTurn));
    expect(p.teams[0].score, 2 * words);
    p.nextRound();
    expect(p.isContinuation, isTrue);

    // Devant au score, l'équipe n'aurait plus droit au ×2 : un nouveau tirage
    // le perdrait. Rien ne tombe sur une continuation, celle du tour reste.
    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenCountdown);
    expect(p.game.fiesta!.turn.drop?.catalogId, 'double_points');
    p.startTurnTimer();
    p.markWordAsGuessed();
    p.endTurn();
    validate(p, List<String>.from(p.game.wordsGuessedThisTurn));

    expect(p.teams[0].score, 2 * words + 2);
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

  test(
      'le malus tombé entre dans `WordEvent.modifiers`, après les malus reçus '
      'qu\'il ne double jamais', () async {
    // Sans le malus reçu, la même graine ferait tomber « Mot à l'envers ».
    final p = await givenDrop('minus_10s',
        received: ['reversed'],
        accept: (g, team) => drawn(g, team)?.catalogId == 'reversed');
    p.startTurn();
    expect(p.droppedThisTurn?.catalogId, 'minus_10s');
    p.leaveTurnReveal();
    p.startTurnTimer();
    final shown = AnalyticsService()
        .currentGame!
        .events
        .lastWhere((e) => e.eventType == WordEventType.shown);
    expect(shown.modifiers, ['reversed', 'minus_10s']);
  });
}
