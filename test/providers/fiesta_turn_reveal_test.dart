import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import 'zero_carryover_turn_test.dart' show givenGame, playTurn, stock;

/// Malus reçus cachés jusqu'à « Commencer le tour », puis « Ce qui t'attend »
/// (retours de recette du 2026-11-15, L-CACHE).
void main() {
  int allotted(GameProvider p) =>
      (p.game.turnEndTimestamp! - p.game.turnStartTimestamp!) ~/ 1000;

  test(
      'aucun malus reçu dans ce que lit l\'avant-tour ; révélés après '
      '« Commencer le tour », et le chrono compte le −10 s', () async {
    final p = await givenGame(2,
        fiesta: stock(['minus_10s', 'block_guesser', 'free_pass']));
    final b = p.teams[1];
    p.inflictMalus('minus_10s', b.playerIds[0]);
    p.inflictMalus('block_guesser', b.playerIds[1]);
    playTurn(p, 0);

    // Avant-tour de B (J3 fait deviner).
    expect(p.getCurrentPlayer()!.id, b.playerIds[0]);
    expect(p.receivedThisTurn, isEmpty);
    expect(p.currentTeamModifiers, isEmpty);
    expect(p.blockedGuesser, isNull);
    expect(p.turnTime.total, p.settings.turnDuration);
    expect(p.reserve.every((c) => c.blockedReason == null), isTrue);

    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenTurnReveal);
    expect(p.receivedThisTurn.map((m) => m.catalogId),
        ['minus_10s', 'block_guesser']);
    expect(p.blockedGuesser!.id, b.playerIds[1]);

    p.leaveTurnReveal();
    expect(p.game.currentScreen, AppConstants.screenCountdown);
    p.startTurnTimer();
    expect(allotted(p), p.settings.turnDuration - 10);
  });

  test(
      '« Ce qui t\'attend » seulement s\'il y a du nouveau, jamais pour le '
      'joueur piégé, dont les autres malus attendent', () async {
    final p = await givenGame(2, fiesta: stock(['block_giver', 'reversed']));
    final b = p.teams[1];
    // Rien de reçu : décompte direct.
    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenCountdown);
    p.goToScreen(AppConstants.screenGame);

    p.inflictMalus('block_giver', b.playerIds[0]);
    p.inflictMalus('reversed', b.playerIds[0]);
    playTurn(p, 0);

    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenCountdown,
        reason: 'le joueur piégé ne voit pas « Ce qui t\'attend »');
    p.startTurnTimer();
    expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
    p.confirmGiverBlock();

    // Le remplaçant n'a rien reçu ; « Mot à l'envers » attend J3.
    expect(p.getCurrentPlayer()!.id, b.playerIds[1]);
    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenCountdown);
    expect(
        p.game.fiesta!.active.where(
            (m) => m.catalogId == 'reversed' && m.playerId == b.playerIds[0]),
        hasLength(1));
  });

  test('app tuée sur « Ce qui t\'attend » : elle y revient', () async {
    final p = await givenGame(2, fiesta: stock(['reversed']));
    p.inflictMalus('reversed', p.teams[1].playerIds[0]);
    playTurn(p, 0);
    p.startTurn();
    expect(p.game.currentScreen, AppConstants.screenTurnReveal);

    await pumpEventQueue();
    final relu = GameProvider();
    await pumpEventQueue();
    expect(relu.game.currentScreen, AppConstants.screenTurnReveal);
    expect(relu.receivedThisTurn.map((m) => m.catalogId), ['reversed']);
  });
}
