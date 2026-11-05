import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/player.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/countdown_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

void main() {
  testWidgets(
      'le tout premier 3-2-1-GO va au même rythme que les suivants '
      '(une seule source de durée)', (tester) async {
    await givenPrefs();
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    for (final name in ['Ana', 'Bob', 'Cid', 'Dan']) {
      final id = (provider.addPlayer(name)['player'] as Player).id;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await tester.runAsync(provider.startGame);
    provider.startTurn();
    expect(provider.game.currentTurnIndex, 0, reason: 'le tour jadis ralenti');

    await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: CountdownScreen()),
    ));
    expect(find.text('3'), findsOneWidget);

    const tick = AppConstants.countdownTick;
    await tester.pump(tick);
    expect(find.text('2'), findsOneWidget);
    await tester.pump(tick);
    expect(find.text('1'), findsOneWidget);
    await tester.pump(tick);
    expect(find.text('GO !'), findsOneWidget);
    expect(provider.game.currentScreen, AppConstants.screenCountdown);

    await tester.pump(AppConstants.countdownGoHold);
    expect(provider.game.currentScreen, AppConstants.screenTurn);
    expect(tick * 3 + AppConstants.countdownGoHold,
        const Duration(milliseconds: 1900));
  });
}
