import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/home_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

/// Monte `HomeScreen` avec un vrai `GameProvider` sur un stockage de test.
Future<GameProvider> pumpHome(WidgetTester tester) async {
  await givenPrefs();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    ),
  );
  // pump() et non pumpAndSettle() : l'écran porte une animation d'étoiles en
  // boucle, sur laquelle pumpAndSettle ne converge jamais.
  await tester.pump();
  return provider;
}

Future<Map<String, dynamic>?> settingsOnDisk() async {
  final raw = await rawString(AppConstants.settingsKey);
  return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  testWidgets(
      'appuyer sur « Jouer » depuis l\'accueil ne réinitialise pas les réglages',
      (tester) async {
    // C'est le VRAI chemin utilisateur. Les tests du provider ne l'attrapent
    // pas : `startNewGame()` préservait déjà les réglages, le défaut était que
    // l'accueil appelait `clearLocalStorage()` à la place.
    final provider = await pumpHome(tester);

    provider.updateSettings(turnDuration: 45, passPenalty: 2);
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();

    expect(find.text('Jouer'), findsOneWidget,
        reason: 'sans partie en cours, l\'accueil propose « Jouer »');

    await tester.tap(find.text('Jouer'));
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();

    expect(provider.settings.turnDuration, 45);
    expect(provider.settings.passPenalty, 2);

    final disk = await settingsOnDisk();
    expect(disk!['turnDuration'], 45,
        reason: 'c\'est le disque que relira la prochaine ouverture de l\'app');
    expect(disk['passPenalty'], 2);
  });

  testWidgets('« Jouer » mène bien à l\'écran de réglages', (tester) async {
    // Pendant du test précédent : préserver les réglages ne doit pas se faire en
    // ne faisant plus rien du tout.
    final provider = await pumpHome(tester);

    await tester.tap(find.text('Jouer'));
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();

    expect(provider.game.currentScreen, AppConstants.screenSettings);
  });
}
