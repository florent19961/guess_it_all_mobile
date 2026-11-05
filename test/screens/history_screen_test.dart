import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/history_screen.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/theme/app_theme.dart';
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

  testWidgets('une équipe garde sa couleur, quel que soit son rang',
      (tester) async {
    // Bleu, 2e équipe de la partie, gagne : aux Résultats elle est en couleur
    // d'équipe 2. Le rang ne doit pas lui donner celle de l'équipe 1.
    await givenPrefs();
    await GameHistoryService()
        .record(game(id: 'a', scores: const {'Rouge': 8, 'Bleu': 12}));
    await pumpHistory(tester);
    await tester.tap(find.text('Bleu gagne'));
    await tester.pumpAndSettle();

    Color pastille(String equipe) => (tester
            .widget<Container>(find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.text(equipe),
                        matching: find.byType(Row),
                      )
                      .first,
                  matching: find.byType(Container),
                )
                .first)
            .decoration as BoxDecoration)
        .color!;

    expect(pastille('Bleu'), AppColors.getTeamColor(1));
    expect(pastille('Rouge'), AppColors.getTeamColor(0));
  });

  testWidgets('les tendances parlent de points et tiennent à 360×640',
      (tester) async {
    // Noms au maximum du champ (18) ; un « ×2 » rend le nombre de mots faux.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await givenPrefs();
    await GameHistoryService().record(game(id: 'a', scores: const {
      'Les Grands Moulins': 30,
      'Bananes Atomiques': 2,
    }));
    await GameHistoryService().record(game(id: 'b', scores: const {
      'Les Grands Moulins': 2,
      'Bananes Atomiques': 3,
    }));
    await GameHistoryService().record(game(id: 'c', scores: const {
      'Les Petits Moulins': 40,
      'Bananes Atomiques': 3,
    }));
    await pumpHistory(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Points par partie'), findsOneWidget);
    expect(find.text('Mots devinés par partie'), findsNothing);
    final libelle = tester.getSize(find.text('Victoires'));
    expect(libelle.height, lessThan(30),
        reason: 'le libellé ne doit pas se replier lettre par lettre');
  });

  testWidgets('une équipe au pluriel gagne au pluriel', (tester) async {
    await givenPrefs();
    await GameHistoryService()
        .record(game(id: 'a', scores: const {'Les Moulins': 12, 'Bleu': 8}));
    await pumpHistory(tester);

    expect(find.text('Les Moulins gagnent'), findsOneWidget);
  });
}
