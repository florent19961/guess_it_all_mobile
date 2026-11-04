import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/screens/fiesta_tutorial_screen.dart';

import '../helpers/test_prefs.dart';

void main() {
  // Bug device : « Continuer » (premier choix de Fiesta) puis « ? » ouvraient
  // le tuto deux fois, l'un sur l'autre.
  testWidgets('le tuto Fiesta ne s\'ouvre pas deux fois', (tester) async {
    await givenPrefs();
    // skipOffstage: false — un tuto recouvert par l'autre est hors scène.
    final tutos = find.byType(FiestaTutorialScreen, skipOffstage: false);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));

    FiestaTutorialScreen.show(context);
    FiestaTutorialScreen.show(context);
    await tester.pumpAndSettle();
    expect(tutos, findsOneWidget);

    // Fermé, il se rouvre.
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    FiestaTutorialScreen.show(context);
    await tester.pumpAndSettle();
    expect(tutos, findsOneWidget);
  });
}
