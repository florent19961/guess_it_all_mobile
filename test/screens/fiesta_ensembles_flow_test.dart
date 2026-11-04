import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensembles_screen.dart';
import 'package:guess_it_all_mobile/widgets/common/app_back_button.dart';
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
    {Size size = const Size(390, 844),
    List<FiestaRules> ensembles = const []}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
    // Écrit à la main : le service sérialise ses écritures sur une file
    // singleton, qu'un test précédent (horloge simulée) peut laisser figée.
    if (ensembles.isNotEmpty)
      FiestaEnsembleService.storageKey: jsonEncode(wrapWithSchema({
        'ensembles': [
          for (final (i, rules) in ensembles.indexed)
            FiestaEnsemble(id: 'e$i', rules: rules).toJson(),
        ],
      })),
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
  // Bug Florent 2026-11-04 : « Donne un nom à l'ensemble » affiché alors que
  // le nom est saisi — l'éditeur en ligne montrait ses erreurs avant toute
  // tentative, et repartait vierge (donc en erreur) juste après un
  // enregistrement réussi. Reproduit sur origin/main avant correction.
  testWidgets(
      'éditeur : « Donne un nom » seulement après Enregistrer avec un nom '
      'vide, effacé dès la saisie ; enregistré, l\'ensemble est sélectionné '
      'et « Suivant » mène aux joueurs avec lui', (tester) async {
    final provider =
        await pumpCustomFiesta(tester, AppConstants.screenFiestaEnsembles);
    const nameError = 'Donne un nom à l\'ensemble.';
    Finder error() => find.text(nameError, skipOffstage: false);

    // Sous les 7 ensembles fournis : liste paresseuse, on y fait défiler.
    await tester.scrollUntilVisible(find.text('Créer un ensemble'), 300,
        scrollable: find.byType(Scrollable).first);
    await tapText(tester, 'Créer un ensemble');
    expect(find.text('Nouvel ensemble'), findsOneWidget);
    expect(error(), findsNothing, reason: 'rien tenté : pas d\'erreur');

    await tapText(tester, 'Enregistrer');
    expect(error(), findsWidgets, reason: 'nom vide, Enregistrer tenté');

    await tester.enterText(find.byType(TextField), 'Soirée chez Max');
    await tester.pump();
    expect(error(), findsNothing, reason: 'nom saisi : plus d\'erreur');

    await tapText(tester, 'Enregistrer');
    expect(find.text('Nouvel ensemble'), findsNothing, reason: 'retour liste');
    expect(error(), findsNothing);
    final stored = await tester.runAsync(() => FiestaEnsembleService().load());
    expect(stored!.ensembles.map((e) => e.name), ['Soirée chez Max']);

    await tapText(tester, 'Suivant');
    expect(provider.game.currentScreen, AppConstants.screenPlayers);
    expect(provider.pendingFiesta?.ensembleName, 'Soirée chez Max',
        reason: 'l\'ensemble enregistré est celui sélectionné');
  });

  testWidgets(
      'brouillons : un par ensemble, aucun n\'en écrase un autre (création A '
      'puis modification B laissées incomplètes, puis reprise de A et de B)',
      (tester) async {
    FiestaEnsemblesScreen.drafts.clear();
    addTearDown(FiestaEnsemblesScreen.drafts.clear);
    await pumpCustomFiesta(tester, AppConstants.screenFiestaEnsembles,
        ensembles: [defaultEnsembleRules('Mien')]);
    Future<void> scrollTo(String text) =>
        tester.scrollUntilVisible(find.text(text), 300,
            scrollable: find.byType(Scrollable).first);
    String nameField() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;
    Future<void> back() async {
      await tester.tap(find.byType(AppBackButton).last);
      await settle(tester);
      // Laisse partir le toast « Brouillon gardé » (il flotte sur la liste).
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
    }

    // A : création, nom déjà pris → incomplet, gardé.
    await scrollTo('Créer un ensemble');
    await tapText(tester, 'Créer un ensemble');
    await tester.enterText(find.byType(TextField), 'Pro Player');
    await tester.pump();
    await back();
    expect(find.text('Nouvel ensemble'), findsNothing);

    // B : modification de « Mien », nom vidé → incomplet, gardé.
    await scrollTo('Modifier');
    await tapText(tester, 'Modifier');
    expect(nameField(), 'Mien');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await back();

    // Reprise de A, intacte ; puis de B, intacte.
    await scrollTo('Reprendre le brouillon');
    await tapText(tester, 'Reprendre le brouillon');
    expect(nameField(), 'Pro Player');
    await back();
    await scrollTo('Modifier');
    await tapText(tester, 'Modifier');
    expect(nameField(), '');
    expect(FiestaEnsemblesScreen.drafts.keys,
        unorderedEquals([FiestaEnsemblesScreen.newDraftKey, isNotEmpty]));
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
