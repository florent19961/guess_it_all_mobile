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

/// Monte l'app complète, en Fiesta Personnalisé, sur [screen].
Future<GameProvider> pumpCustomFiesta(WidgetTester tester, String screen,
    {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
  });
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  provider.setPendingFiesta(FiestaRules(mode: FiestaMode.custom));
  provider.goToScreen(screen);

  await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
    value: provider,
    child: const GuessItAllApp(),
  ));
  await settle(tester);
  // L'intro de démarrage (au-dessus de tout) doit finir de s'effacer.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return provider;
}

void main() {
  // Bug Florent 2026-11-04 (Chrome) : aucun ensemble, « Créer un ensemble »
  // ouvrait une page à part sans « Suivant » ; on n'en sortait que par le
  // retour, qui jetait la saisie : cul-de-sac, liste toujours vide.
  testWidgets(
      'Personnalisé sans ensemble : créer, enregistrer, l\'ensemble est '
      'sélectionné et « Suivant » mène aux joueurs avec lui', (tester) async {
    final provider =
        await pumpCustomFiesta(tester, AppConstants.screenFiestaEnsembles);

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

  testWidgets(
      'Personnalisé : « Suivant » des Paramètres mène à l\'écran des '
      'ensembles, avant les joueurs', (tester) async {
    // Surface large : Paramètres déborde avec la police de test.
    final provider = await pumpCustomFiesta(tester, AppConstants.screenSettings,
        size: const Size(700, 1300));
    // Mots écrits à la main : pas de comptage des fichiers de mots, dont le
    // chargement ne se termine pas sous l'horloge simulée du test.
    provider.updateSettings(wordChoice: AppConstants.wordChoiceCustom);
    await settle(tester);

    await tapText(tester, 'Suivant');
    expect(provider.game.currentScreen, AppConstants.screenFiestaEnsembles);
  });
}
