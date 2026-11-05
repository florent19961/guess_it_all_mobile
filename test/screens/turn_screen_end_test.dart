import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/turn_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

void main() {
  // Bug device : la fin de tour passait par un `addPostFrameCallback`, qui ne
  // DEMANDE pas de frame. Pendant la dernière seconde rien ne notifie ni
  // n'anime l'écran : le tour restait sur « 1s » jusqu'à un toucher.
  // Ici, aucun `pump` après le premier rendu : un `pump` produirait la frame
  // qui masque le bug. `binding.delayed` fait seulement avancer les timers.
  testWidgets('le chrono à zéro termine le tour sans aucune frame extérieure',
      (tester) async {
    await givenPrefs();
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await tester.runAsync(() async {
      await pumpEventQueue();
      for (final name in ['A', 'B', 'C', 'D']) {
        final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
        provider.updatePlayerWords(id, ['$name-1', '$name-2', '$name-3']);
      }
      provider.createTeams();
      provider.randomizeTeams();
      provider.updateSettings(turnDuration: 10, passPenalty: 9);
      await provider.startGame();
    });
    provider.startTurn();
    provider.startTurnTimer();
    // 10 s (plancher du tour) − 9 s de pénalité : il reste une seconde, gelée
    // le temps du rendu pour qu'elle ne s'écoule pas avant le départ du test.
    provider.passWord();
    provider.pauseTurn();

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: provider,
        child: const MaterialApp(home: TurnScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600)); // fin des animations
    expect(provider.game.currentScreen, AppConstants.screenTurn);
    provider.resumeTurn();

    // Le temps du tour est en horloge murale : on le laisse vraiment expirer.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)));

    // Le tick du Timer (100 ms) tourne ; aucune frame n'est produite.
    await tester.binding.delayed(const Duration(milliseconds: 200));

    expect(provider.game.currentScreen, AppConstants.screenVerification,
        reason: 'le tour attend une frame qui n\'arrive jamais');
  });
}
