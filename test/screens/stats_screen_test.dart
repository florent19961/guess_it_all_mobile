import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/stats_screen.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

/// Un état de partie terminée, avec de quoi remplir les classements.
///
/// On passe par le STOCKAGE plutôt que par un setter de test : c'est le seul
/// chemin d'alimentation réel du provider, et ça évite d'ouvrir une porte dans
/// le code de production pour les seuls besoins d'un test.
Map<String, Object> _partieJouee() {
  Map<String, dynamic> tour(
          String joueur, String equipe, int round, int devines, int temps) =>
      {
        'round': round,
        'turn': 1,
        'teamId': equipe,
        'playerId': joueur,
        'wordsGuessed': List.generate(devines, (i) => 'mot-$joueur-$round-$i'),
        'wordsInvalidated': <String>[],
        'wordsPassed': <String>[],
        'timeSpent': temps,
      };

  return {
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
          'score': 9,
          'scoreByRound': [5, 4, 0],
        },
        {
          'id': 't2',
          'name': 'Bleu',
          'playerIds': ['p2'],
          'score': 4,
          'scoreByRound': [2, 2, 0],
        },
      ],
      'game': {
        'gameId': 'g-stats',
        'currentRound': 3,
        'history': [
          // Alice devine plus, et plus vite.
          tour('p1', 't1', 1, 5, 30),
          tour('p2', 't2', 1, 2, 30),
          tour('p1', 't1', 2, 4, 30),
          tour('p2', 't2', 2, 2, 30),
        ],
      },
    })),
  };
}

Future<void> pumpStats(WidgetTester tester, Map<String, Object> seed) async {
  await givenPrefs(seed);
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: StatsScreen())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('les classements s\'affichent avec les vrais joueurs',
      (tester) async {
    // 🔴 Ce test existe parce que le rendu des statistiques a été réécrit
    // (quatre builders copiés fusionnés en un) et qu'AUCUN test ne le
    // couvrait : les agrégations sont pures et testées, mais rien ne prouvait
    // que l'écran les affiche encore.
    await pumpStats(tester, _partieJouee());

    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.text('Top joueurs'), findsOneWidget);

    // Alice a deviné 9 mots au total, Bob 4.
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('9'), findsWidgets);

    // Les classements par manche vivent derrière « Cherry on the cake » : ce
    // sont eux qui étaient des copies intégrales du bloc « partie entière ».
    expect(find.text('Temps moyen par mot (partie entière)'), findsNothing);

    // La carte « Top joueurs » pousse le dépliant hors du viewport de test :
    // sans ce scroll, le tap tombe dans le vide au lieu d'ouvrir la section.
    await tester.ensureVisible(find.text('Cherry on the cake'));
    await tester.pump();
    await tester.tap(find.text('Cherry on the cake'));
    await tester.pump();

    expect(find.text('Temps moyen par mot (partie entière)'), findsOneWidget);
    expect(find.text('Top joueurs (manche 1)'), findsOneWidget);
    expect(find.text('Temps moyen par mot (manche 2)'), findsOneWidget);
  });

  testWidgets('le classement par manche ne montre QUE cette manche',
      (tester) async {
    // La régression que le refactor pouvait introduire en silence : un
    // paramètre `round` oublié ferait afficher les chiffres de la partie
    // entière sous un titre « manche N ».
    await pumpStats(tester, _partieJouee());
    // La carte « Top joueurs » pousse le dépliant hors du viewport de test :
    // sans ce scroll, le tap tombe dans le vide au lieu d'ouvrir la section.
    await tester.ensureVisible(find.text('Cherry on the cake'));
    await tester.pump();
    await tester.tap(find.text('Cherry on the cake'));
    await tester.pump();

    // Alice : 5 mots en manche 1, 4 en manche 2, 9 au total. Si le filtre
    // sautait, on verrait 9 sous le titre de la manche 1.
    final carte = find.ancestor(
      of: find.text('Top joueurs (manche 1)'),
      matching: find.byType(Container),
    );
    expect(find.descendant(of: carte.first, matching: find.text('5')),
        findsOneWidget);
    expect(find.descendant(of: carte.first, matching: find.text('9')),
        findsNothing);
  });

  testWidgets('un écran sans historique ne lève pas et n\'affiche rien de faux',
      (tester) async {
    // Le cas limite du refactor : `rows.first` / `rows.last` sur une liste vide
    // lèverait. L'ancien code renvoyait `SizedBox()`, le nouveau doit aussi.
    await pumpStats(tester, const {});

    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.text('Top joueurs'), findsNothing,
        reason: 'sans donnée, la carte ne doit pas être montée du tout');
  });
}
