import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/results_screen.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

Future<void> pumpResults(WidgetTester tester,
    {Map<String, dynamic>? fiesta}) async {
  await givenPrefs({
    AppConstants.gameStateKey: jsonEncode(wrapWithSchema({
      'players': [
        {'id': 'p1', 'name': 'Alice', 'words': <String>[]},
        {'id': 'p2', 'name': 'Bob', 'words': <String>[]},
      ],
      'teams': [
        {
          'id': 't1',
          'name': 'Rouge',
          'playerIds': ['p1'],
          'score': 1,
          'scoreByRound': [1, 0, 0],
        },
        {
          'id': 't2',
          'name': 'Bleu',
          'playerIds': ['p2'],
          'score': 9,
          'scoreByRound': [2, 3, 4],
        },
      ],
      'game': {
        'gameId': 'g',
        'currentRound': 3,
        'teamPlayOrder': [0, 1],
        if (fiesta != null) 'fiesta': fiesta,
      },
    })),
  });
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: ResultsScreen())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('le podium accorde « pt » et reprend les totaux du détail',
      (tester) async {
    await pumpResults(tester);

    expect(find.text('1 pt'), findsOneWidget);
    expect(find.text('9 pts'), findsOneWidget);
    expect(find.text('1 pts'), findsNothing);

    // Détail : M1, M2, M3 puis total, gagnant d'abord.
    final textes =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    final debut = textes.indexOf('Total') + 1;
    expect(textes.sublist(debut, debut + 10),
        ['Bleu', '2', '3', '4', '9', 'Rouge', '1', '0', '0', '1']);
  });

  testWidgets(
      'Fiesta : plus de carte des modificateurs, le reste de l\'écran ne bouge pas',
      (tester) async {
    await pumpResults(tester,
        fiesta: FiestaState(
          rules: FiestaRules(
            drawCount: 0,
            trailingCount: 0,
            modifiers: const {'plus_10s': ModifierSetting(charges: 1)},
          ),
          chargesUsed: const [
            ChargeUse(catalogId: 'plus_10s', teamId: 't1', round: 1, turn: 1),
          ],
        ).toJson());
    final provider =
        tester.element(find.byType(ResultsScreen)).read<GameProvider>();
    expect(provider.isFiesta, isTrue);

    expect(find.text('Modificateurs de la partie'), findsNothing);
    expect(find.textContaining('Bonus de 10 s'), findsNothing);
    expect(find.text('9 pts'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);
    expect(find.text('Voir les statistiques'), findsOneWidget);
    // Les faits restent, pour l'archive.
    expect(provider.modifierRecap.single.title, 'Cartouches utilisées');
  });
}
