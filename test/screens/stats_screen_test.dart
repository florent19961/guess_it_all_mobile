import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
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

/// Une partie dont l'historique est donné tel quel, scores recalculés à la main
/// par le test : équipes t1 (p1) et t2 (p2).
Map<String, Object> _partieAvec(List<Map<String, dynamic>> history) => {
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
          },
          {
            'id': 't2',
            'name': 'Bleu',
            'playerIds': ['p2'],
          },
        ],
        'game': {'gameId': 'g', 'currentRound': 3, 'history': history},
      })),
    };

Map<String, dynamic> _entree(int round, String equipe, int mots, int temps,
        {bool continuation = false}) =>
    {
      'round': round,
      'turn': 1,
      'teamId': equipe,
      'playerId': equipe == 't1' ? 'p1' : 'p2',
      'wordsGuessed': List.generate(mots, (i) => 'm$round-$equipe-$i'),
      'wordsInvalidated': <String>[],
      'wordsPassed': <String>[],
      'timeSpent': temps,
      'isBonusContinuation': continuation,
    };

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

  group('Évolution des scores', () {
    List<VerticalLine> barres(WidgetTester tester) => tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .extraLinesData
        .verticalLines;

    testWidgets('une manche jouée en continuation garde sa barre et son nom',
        (tester) async {
      // t1 finit M1 à son 2e tour, joue TOUTE la M2 sur le temps reporté, et
      // ouvre la M3 de même. t2 ne rejoue qu'ensuite : aucun tour normal en M2.
      await pumpStats(
          tester,
          _partieAvec([
            _entree(1, 't1', 3, 30),
            _entree(1, 't2', 2, 30),
            _entree(1, 't1', 1, 20),
            _entree(2, 't1', 6, 8, continuation: true),
            _entree(3, 't1', 2, 2, continuation: true),
            _entree(3, 't2', 4, 30),
          ]));

      final lignes = barres(tester);
      expect(lignes.map((l) => l.label.labelResolver(l)), ['M1', 'M2', 'M3']);
      // M1 au départ ; M2 et M3 démarrent toutes deux au 2e tour de t1.
      expect(lignes.map((l) => l.x), [0, 2, 2]);
    });

    testWidgets('la barre de M2 suit la continuation, pas le tour d\'après',
        (tester) async {
      // t2 finit M1 à son 2e tour : la courbe de t2 en x=2 contient déjà des
      // mots de M2, la barre ne peut pas être à droite de ce point.
      await pumpStats(
          tester,
          _partieAvec([
            _entree(1, 't1', 3, 30),
            _entree(1, 't2', 2, 30),
            _entree(1, 't1', 1, 30),
            _entree(1, 't2', 2, 20),
            _entree(2, 't2', 3, 10, continuation: true),
            _entree(2, 't1', 4, 30),
          ]));

      expect(barres(tester).map((l) => l.x), [0, 2]);
    });

    testWidgets('l\'axe des scores ne double pas son dernier repère',
        (tester) async {
      // Maximum 47 : axe jusqu'à 51,7, repères tous les 12. Le dernier repère
      // automatique (51) mordait sur le 48.
      await pumpStats(
          tester,
          _partieAvec([
            _entree(1, 't1', 47, 30),
            _entree(1, 't2', 5, 30),
          ]));

      expect(find.text('48'), findsOneWidget);
      expect(find.text('51'), findsNothing);
    });

    testWidgets('score maximal à 1 : un seul repère « 1 »', (tester) async {
      await pumpStats(
          tester,
          _partieAvec([
            _entree(1, 't1', 1, 30),
          ]));

      final axe =
          find.descendant(of: find.byType(LineChart), matching: find.text('1'));
      // Un repère vertical et un horizontal (tour 1), pas un de plus.
      expect(axe, findsNWidgets(2));
    });

    testWidgets('une entrée d\'équipe inconnue ne fait pas tomber l\'écran',
        (tester) async {
      // `HistoryEntry.fromJson` met '' à un teamId absent, pour qu'une entrée
      // incomplète ne rende pas la partie illisible.
      await pumpStats(
          tester,
          _partieAvec([
            _entree(1, 't1', 3, 30),
            _entree(1, '', 2, 30),
            _entree(2, '', 1, 5, continuation: true),
          ]));

      expect(tester.takeException(), isNull);
      expect(find.text('Évolution des scores'), findsOneWidget);
    });
  });

  testWidgets(
      'temps moyen : le plus rapide a la barre la plus longue, même à 0 s',
      (tester) async {
    // Dernier mot trouvé dans la première seconde d'une continuation : 0 s
    // comptée (secondes arrondies au supérieur à l'écran).
    await pumpStats(
        tester,
        _partieAvec([
          _entree(3, 't1', 1, 0, continuation: true),
          _entree(3, 't2', 2, 8),
        ]));
    await tester.ensureVisible(find.text('Cherry on the cake'));
    await tester.pump();
    await tester.tap(find.text('Cherry on the cake'));
    await tester.pump();

    final barres = tester
        .widgetList<FractionallySizedBox>(find.descendant(
          of: find
              .ancestor(
                of: find.text('Temps moyen par mot (partie entière)'),
                matching: find.byType(Container),
              )
              .first,
          matching: find.byType(FractionallySizedBox),
        ))
        .map((b) => b.widthFactor)
        .toList();
    // Alice 0,0 s puis Bob 4,0 s.
    expect(barres, [1.0, 0.2]);
  });
}
