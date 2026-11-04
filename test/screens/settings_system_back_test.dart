import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/settings_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

void main() {
  // Revue r1 (MAJOR) : Paramètres est l'écran racine du `MaterialApp`, le
  // retour système d'Android quittait l'app au lieu de revenir à l'accueil.
  testWidgets('retour système sur Paramètres → accueil, l\'app reste ouverte',
      (tester) async {
    await givenPrefs();
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    provider.goToScreen(AppConstants.screenSettings);

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    // pump() : animations en boucle, pumpAndSettle ne converge pas.
    await tester.pump();

    final handled = await tester.binding.handlePopRoute();

    expect(handled, isTrue, reason: 'non géré = l\'app se ferme');
    expect(provider.game.currentScreen, AppConstants.screenHome);
  });
}
