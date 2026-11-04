import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

/// Laisse tourner les Futures réelles (stockage) puis redessine. pump() et
/// non pumpAndSettle() : fonds animés en boucle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}

void main() {
  // Bug Florent 2026-11-04 (Chrome) : aucun ensemble, « Créer un ensemble »
  // ouvrait une page à part sans « Suivant » ; on n'en sortait que par le
  // retour, qui jetait la saisie : cul-de-sac, liste toujours vide.
  testWidgets(
      'Personnalisé sans ensemble : créer, enregistrer, l\'ensemble est '
      'sélectionné et « Suivant » mène aux joueurs avec lui', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs({
      AppConstants.tutorialSeenKey: true,
      'guessItAll_fiestaTutorialSeen': true,
    });
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await tester.runAsync(() => pumpEventQueue());
    provider.setPendingFiesta(FiestaRules(mode: FiestaMode.custom));
    // Arrivée depuis Paramètres (sa mise en page déborde avec la police de
    // test : on entre directement sur l'écran).
    provider.goToScreen(AppConstants.screenFiestaEnsembles);

    await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const GuessItAllApp(),
    ));
    await settle(tester);
    await tester.pump(const Duration(seconds: 2)); // intro de démarrage

    await tester.enterText(find.byType(TextField), 'Soirée chez Max');
    await tester.pump();
    await tapText(tester, 'Enregistrer');

    final stored = await tester.runAsync(() => FiestaEnsembleService().load());
    expect(stored!.ensembles.map((e) => e.name), ['Soirée chez Max']);
    expect(provider.game.currentScreen, AppConstants.screenFiestaEnsembles,
        reason: 'on reste sur l\'écran, l\'ensemble apparaît dans la liste');

    await tapText(tester, 'Suivant');
    expect(provider.game.currentScreen, AppConstants.screenPlayers);
    expect(provider.pendingFiesta?.ensembleName, 'Soirée chez Max',
        reason: 'l\'ensemble enregistré est celui sélectionné');
  });
}
