import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/app.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/surprise_challenge.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_editor_screen.dart';
import 'package:guess_it_all_mobile/screens/fiesta_ensemble_view_screen.dart';
import 'package:guess_it_all_mobile/screens/game_screen.dart';
import 'package:guess_it_all_mobile/screens/surprise_challenge_screen.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

Future<void> _loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await (FontLoader('Bangers')
        ..addFont(rootBundle.load('assets/fonts/Bangers-Regular.ttf')))
      .load();
  await (FontLoader('Poppins')
        ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf')))
      .load();
}

/// L'app complète, à la fin de la manche 1 d'une partie avec un défi après M1.
Future<GameProvider> _pumpEndOfRound1(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await givenPrefs({
    AppConstants.tutorialSeenKey: true,
    AppConstants.fiestaTutorialSeenKey: true,
    AppConstants.firstGameDoneKey: true,
  });
  givenFakePlatformPlugins();
  final p = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  for (final name in ['Ana', 'Bob', 'Léo', 'Sam']) {
    final id = (p.addPlayer(name)['player'] as dynamic).id as String;
    p.updatePlayerWords(id, ['mot-$name']);
  }
  p.createTeams();
  p.randomizeTeams();
  await tester
      .runAsync(() => p.startGame(fiesta: FiestaRules(challenges: true)));

  var i = 0;
  while (!drawChallengeSchedule('game-$i').containsKey(1)) {
    i++;
  }
  p.goToScreen(AppConstants.screenVerification);
  p.savePreValidationState(const []);
  p.game.preValidationSnapshot!['game'] = {
    ...p.game.preValidationSnapshot!['game'] as Map<String, dynamic>,
    'gameId': 'game-$i',
  };
  p.restorePreValidationState();
  p.goToScreen(AppConstants.screenGame);

  p.startTurn();
  p.startTurnTimer();
  while (p.game.currentWord != null) {
    p.markWordAsGuessed();
  }
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);

  await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
    value: p,
    child: const GuessItAllApp(),
  ));
  await tester.pump();
  return p;
}

/// L'animation de manche enchaîne seule jusqu'au VS.
Future<void> _toChallenge(WidgetTester tester) async {
  expect(find.byType(SurpriseChallengeScreen), findsNothing);
  for (var n = 0; n < 60; n++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(SurpriseChallengeScreen).evaluate().isNotEmpty) break;
  }
  expect(find.byType(SurpriseChallengeScreen), findsOneWidget);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('animation de manche, défi gagné, puis écran avant le tour',
      (tester) async {
    final p = await _pumpEndOfRound1(tester);
    await _toChallenge(tester);
    final plan = p.currentChallenge!;
    final winner = p.getPlayerById(plan.second.playerId)!.name;
    final teamName = p.teams.firstWhere((t) => t.id == plan.second.teamId).name;
    expect(find.text('VS'), findsOneWidget);
    expect(find.text(winner), findsOneWidget);

    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('C\'est parti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    if (plan.challenge == SurpriseChallenge.clapping) {
      for (var n = 0; n < 12; n++) {
        await tester.pump(const Duration(seconds: 1));
      }
    } else {
      await tester.tapAt(const Offset(180, 620));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(winner).last);
    await tester.pump();
    await tester.pump(kRouletteDuration);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('$teamName gagnent !'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(p.game.fiesta!.earned.last.teamId, plan.second.teamId);
    expect(p.game.fiesta!.earned.last.catalogId, plan.second.prizeId);
  });

  testWidgets('« Passer ce défi » va à l\'écran avant le tour, sans gain',
      (tester) async {
    final p = await _pumpEndOfRound1(tester);
    await _toChallenge(tester);
    await tester.tap(find.text('Passer ce défi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(p.game.fiesta!.earned, isEmpty);
  });

  testWidgets('gagnant choisi puis « Passer » : ni cartouche, ni rejeu',
      (tester) async {
    final p = await _pumpEndOfRound1(tester);
    await _toChallenge(tester);
    final plan = p.currentChallenge!;
    await tester.pump(kVersusDuration);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('C\'est parti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    if (plan.challenge == SurpriseChallenge.clapping) {
      for (var n = 0; n < 11; n++) {
        await tester.pump(const Duration(seconds: 1));
      }
    } else {
      await tester.tapAt(const Offset(180, 620));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester
        .tap(find.text(p.getPlayerById(plan.first.playerId)!.name).last);
    await tester.pump();

    expect(p.game.fiesta!.earned, isEmpty, reason: 'pas avant « Continuer »');
    await tester.tap(find.text('Passer ce défi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(p.game.fiesta!.earned, isEmpty);
    expect(p.game.fiesta!.challenges.single.prize, isNull);
  });

  testWidgets('éditeur : réglage replié derrière « pousser plus loin »',
      (tester) async {
    // Assez haut pour tout voir sans défiler.
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: FiestaEnsembleEditorScreen(others: []),
    ));
    await tester.pump();
    await tester.tap(find.textContaining('Cartouches').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Défis surprises'), findsNothing);

    await tester.tap(find.textContaining('pousser plus loin'));
    await tester.pump();
    expect(find.text('Défis surprises'), findsOneWidget);
    expect(find.textContaining('moins rapide'), findsNothing);
  });

  testWidgets('page Voir : le réglage est affiché', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: FiestaEnsembleViewScreen(
        ensemble: FiestaEnsemble(
          id: 'mine',
          rules: FiestaRules(ensembleName: 'Ensemble', challenges: true),
        ),
        canDuplicate: false,
      ),
    ));
    await tester.pump();
    expect(find.textContaining('Défis surprises'), findsOneWidget);
  });
}
