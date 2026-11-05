import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/results_screen.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

Future<void> pumpResults(WidgetTester tester) async {
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
}
