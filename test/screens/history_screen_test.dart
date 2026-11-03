import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/history_screen.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

GameResult game({
  required String id,
  Map<String, int> scores = const {'Rouge': 12, 'Bleu': 8},
}) =>
    GameResult(
      gameId: id,
      playedAt: DateTime(2026, 3, 14, 21, 5),
      teams: scores.entries
          .map((e) => TeamResult(
                id: e.key.toLowerCase(),
                name: e.key,
                score: e.value,
                scoreByRound: [e.value, 0, 0],
                playerNames: ['${e.key}-1'],
              ))
          .toList(),
      totalWords: 40,
      turnDuration: 30,
      roundsPlayed: 3,
    );

Future<void> pumpHistory(WidgetTester tester) async {
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
    ),
  );
  // Le chargement est asynchrone : on laisse le FutureBuilder se résoudre.
  await tester.runAsync(() => pumpEventQueue());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans partie terminée, l\'écran explique qu\'il est vide',
      (tester) async {
    await givenPrefs();
    await pumpHistory(tester);

    expect(find.text('Aucune partie terminée'), findsOneWidget);
  });

  testWidgets('affiche le vainqueur, les scores et les tendances',
      (tester) async {
    await givenPrefs();
    await GameHistoryService().record(game(id: 'a'));
    await pumpHistory(tester);

    expect(find.text('Rouge gagne'), findsOneWidget);
    expect(find.text('12 – 8'), findsOneWidget,
        reason: 'les scores sont classés par ordre décroissant');
    expect(find.text('Tendances'), findsOneWidget);
  });

  testWidgets('une égalité n\'invente pas de vainqueur', (tester) async {
    await givenPrefs();
    await GameHistoryService()
        .record(game(id: 'a', scores: const {'Rouge': 9, 'Bleu': 9}));
    await pumpHistory(tester);

    expect(find.textContaining('Égalité'), findsOneWidget);
  });

  testWidgets('déplier une partie révèle le détail par manche', (tester) async {
    await givenPrefs();
    await GameHistoryService().record(game(id: 'a'));
    await pumpHistory(tester);

    // Replié : le détail des manches n'est pas monté.
    expect(find.textContaining('M1:'), findsNothing);

    await tester.tap(find.text('Rouge gagne'));
    await tester.pumpAndSettle();

    expect(find.textContaining('M1:'), findsWidgets);
    expect(find.textContaining('40 mots'), findsOneWidget);
  });
}
