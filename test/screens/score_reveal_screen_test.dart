import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/score_timeline.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/results_screen.dart';
import 'package:guess_it_all_mobile/screens/score_reveal_screen.dart';
import 'package:guess_it_all_mobile/screens/transition_screen.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/services/reveal_sound.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';
import '../providers/fiesta_v4_test.dart' as lot1;

class FakeSound implements RevealSound {
  final calls = <String>[];

  /// Remplace la musique qui démarre : échec ou lecture qui traîne.
  Future<void> Function()? onStart;

  @override
  Future<void> startMusic() async {
    calls.add('music');
    await onStart?.call();
  }

  @override
  void fadeOutMusic() => calls.add('fade');
  @override
  void stopMusic() => calls.add('stop');
}

/// 2 équipes de 2 joueurs, 1 mot par joueur.
Future<GameProvider> givenProvider(WidgetTester tester, {int teams = 2}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await tester.runAsync(() async {
    await pumpEventQueue();
    provider.updateSettings(numberOfTeams: teams);
    for (var i = 0; i < teams * 2; i++) {
      final id = (provider.addPlayer('J$i')['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$i']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    provider.updateTeamName(provider.teams[0].id, 'Les A');
    provider.updateTeamName(provider.teams[1].id, 'Bob');
    await provider.startGame();
  });
  return provider;
}

/// Un tour où l'équipe trouve tout : la manche se termine.
void playRoundInOneTurn(GameProvider p) {
  p.startTurn();
  p.startTurnTimer();
  while (p.game.currentScreen == AppConstants.screenTurn) {
    p.markWordAsGuessed();
  }
  if (p.game.currentScreen != AppConstants.screenVerification) p.endTurn();
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);
}

void playToTheEnd(GameProvider p) {
  // Après M3 aussi : le « Voir les résultats » de l'écran fixe appelle `nextRound`.
  for (var round = 1; round <= 3; round++) {
    playRoundInOneTurn(p);
    p.nextRound();
  }
  expect(p.game.currentScreen, AppConstants.screenResults);
}

Widget app(GameProvider provider, FakeSound sound,
        {bool reduced = false, double textScale = 1}) =>
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              disableAnimations: reduced,
              textScaler: TextScaler.linear(textScale)),
          child: EndOfGameScreen(sound: sound),
        ),
      ),
    );

/// L'aiguillage de `app.dart` pour la fin de partie.
Widget flow(GameProvider provider, FakeSound sound) =>
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Consumer<GameProvider>(
          builder: (_, p, __) => switch (p.game.currentScreen) {
            AppConstants.screenTransition => const TransitionScreen(),
            AppConstants.screenResults => EndOfGameScreen(sound: sound),
            _ => const SizedBox(),
          },
        ),
      ),
    );

/// Depuis la vérification du dernier tour restaurée : revalide.
void revalidate(GameProvider p) {
  final words = List<String>.from(p.game.restoredValidatedWords ?? const []);
  p.clearRestoredValidatedWords();
  p.savePreValidationState(words);
  p.validateWords(words);
}

void main() {
  testWidgets(
      'parcours M3 : la révélation part du bouton de l\'écran fixe, une fois',
      (tester) async {
    final provider = await givenProvider(tester);
    for (var round = 1; round <= 2; round++) {
      playRoundInOneTurn(provider);
      provider.nextRound();
    }
    playRoundInOneTurn(provider);
    final sound = FakeSound();
    await tester.pumpWidget(flow(provider, sound));
    await tester.pump();
    expect(provider.game.currentScreen, AppConstants.screenTransition);
    expect(find.byType(ScoreRevealScreen), findsNothing);
    expect(sound.calls, isEmpty);

    // Retour arrière depuis l'écran fixe : pas de révélation.
    provider.restorePreValidationState();
    await tester.pump();
    expect(provider.game.currentScreen, AppConstants.screenVerification);
    expect(provider.game.scoreRevealSeen, isFalse);
    expect(sound.calls, isEmpty);
    revalidate(provider);
    await tester.pump();
    expect(find.byType(ScoreRevealScreen), findsNothing);

    await tester.tap(find.text('Voir les résultats'));
    await tester.pump();
    expect(find.byType(ScoreRevealScreen), findsOneWidget);
    expect(sound.calls, ['music']);
    await tester.tap(find.byType(ScoreRevealScreen));
    await tester.pump();
    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(provider.game.scoreRevealSeen, isTrue);

    // Correction après les résultats : retour direct, pas de seconde révélation.
    sound.calls.clear();
    provider.restorePreValidationState();
    await tester.pump();
    revalidate(provider);
    await tester.pump();
    await tester.tap(find.text('Voir les résultats'));
    await tester.pump();
    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.byType(ScoreRevealScreen), findsNothing);
    expect(sound.calls, isEmpty);

    final archived = await tester.runAsync(() async {
      await pumpEventQueue();
      return GameHistoryService().load();
    });
    expect(archived, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  test('le piège ne fausse pas les courbes, cartouche rendue datée de son tour',
      () async {
    final p = await lot1
        .givenGame(lot1.stock({'block_giver': 1, 'reversed': 1}), a: 3, b: 3);
    lot1.orderFixed(p);
    lot1.playEmptyTurn(p); // Tour 1 : J0.
    lot1.playEmptyTurn(p); // Tour 2 : J3.
    final victim = p.teams[1].playerIds[1];
    expect(
        p.inflictMalus('block_giver', p.teams[1].id, playerId: victim), isNull);
    lot1.playEmptyTurn(p); // Tour 3 : J1 nomme J4.
    final trapped = p.game.currentTurn;

    // J4 prépare un malus, puis tombe dans le piège : il est rendu.
    expect(p.getCurrentPlayer()!.id, victim);
    expect(p.inflictMalus('reversed', p.teams[0].id), isNull);
    p.startTurn();
    p.startTurnTimer();
    p.confirmGiverBlock();
    List<String> used() =>
        [for (final u in p.game.fiesta!.chargesUsed) u.catalogId];
    expect(used(), ['block_giver']);

    // Le remplaçant le reprend : une seule cartouche, datée de ce tour.
    p.reuseReplacedChoices();
    expect(used(), ['block_giver', 'reversed']);
    lot1.playEmptyTurn(p);
    expect(p.game.fiesta!.chargesUsed.map((u) => u.turn), [3, trapped]);

    for (var round = 1; round <= 3; round++) {
      lot1.finishRound(p);
      p.nextRound();
    }
    expect(p.game.currentScreen, AppConstants.screenResults);

    final history = p.game.history;
    expect(history.where((h) => h.playerId == victim && h.turn == trapped),
        isEmpty,
        reason: 'le tour sauté n\'a pas d\'étape');
    final timeline = buildScoreTimeline(
      teamIds: [for (final t in p.teams) t.id],
      history: history,
    );
    expect(timeline.steps, history.length);
    expect([for (final s in timeline.series) s.last],
        [for (final t in p.teams) t.score]);
    expect([
      for (final u in p.game.fiesta!.chargesUsed)
        (u.catalogId, entryOfCharge(u, history))
    ], [
      ('block_giver', history.indexWhere((h) => h.turn == 3)),
      ('reversed', history.indexWhere((h) => h.turn == trapped)),
    ]);
  });

  testWidgets('fin de partie : animation, puis vainqueur, puis les résultats',
      (tester) async {
    final provider = await givenProvider(tester);
    playToTheEnd(provider);
    final sound = FakeSound();
    await tester.pumpWidget(app(provider, sound));

    expect(find.byType(ScoreRevealScreen), findsOneWidget);
    expect(find.text('Qui a mené la danse ?'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);
    expect(sound.calls, ['music']);

    await tester.pump(); // La musique a démarré : le tracé part.
    await tester.pump(const Duration(milliseconds: 4400));
    expect(find.text('Suivant'), findsNothing, reason: 'environ 4,5 s');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Finale'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(sound.calls, ['music'],
        reason: 'la queue du gong sonne jusqu\'au bout');
    final winner = provider.getTeamsSortedByScore().first;
    expect(find.text(winner.name == 'Bob' ? 'Bob gagne !' : 'Les A gagnent !'),
        findsOneWidget);
    expect(
        find.textContaining('${winner.name} ${winner.score}'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(sound.calls, isNot(contains('fade')),
        reason: 'pas de fondu sur le gong');
    expect(provider.game.scoreRevealSeen, isTrue);
    expect(find.byType(ResultsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('un toucher pendant l\'animation va directement aux résultats',
      (tester) async {
    final provider = await givenProvider(tester);
    playToTheEnd(provider);
    final sound = FakeSound();
    await tester.pumpWidget(app(provider, sound));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(ScoreRevealScreen));
    await tester.pump();

    expect(provider.game.scoreRevealSeen, isTrue);
    expect(find.byType(ScoreRevealScreen), findsNothing);
    expect(sound.calls, contains('fade'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('animations réduites : la fin directement, sans musique',
      (tester) async {
    final provider = await givenProvider(tester);
    playToTheEnd(provider);
    final sound = FakeSound();
    await tester.pumpWidget(app(provider, sound, reduced: true));
    await tester.pump();

    expect(find.text('Finale'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(sound.calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (label, size, scale) in [
    ('360×640, texte × 1,3', const Size(360, 640), 1.3),
    ('360×640, texte × 2', const Size(360, 640), 2.0),
    ('paysage 640×360', const Size(640, 360), 1.0),
    ('paysage 640×360, texte × 2', const Size(640, 360), 2.0),
  ]) {
    testWidgets('4 équipes, $label : pas de débordement, bouton atteignable',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = await givenProvider(tester, teams: 4);
      playToTheEnd(provider);
      await tester.pumpWidget(
          app(provider, FakeSound(), reduced: true, textScale: scale));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.text('Suivant'));
      expect(button.bottom, lessThanOrEqualTo(size.height));
      expect(button.top, greaterThanOrEqualTo(0));
      await tester.tap(find.text('Suivant'));
      expect(provider.game.scoreRevealSeen, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('égalité de points : jamais d\'égalité, la règle de Résultats',
      (tester) async {
    final provider = await givenProvider(tester);
    playToTheEnd(provider);
    provider.teams[0] = provider.teams[0].copyWith(score: 5);
    provider.teams[1] = provider.teams[1].copyWith(score: 5);
    final winner = provider.teams[provider.game.teamPlayOrder.last];
    expect(provider.getTeamsSortedByScore().first.id, winner.id);

    await tester.pumpWidget(app(provider, FakeSound(), reduced: true));
    await tester.pump();

    expect(find.textContaining('Égalité'), findsNothing);
    expect(find.text(winner.name == 'Bob' ? 'Bob gagne !' : 'Les A gagnent !'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('une fois seulement : correction du dernier tour, partie suivante',
      () async {
    await givenPrefs();
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await pumpEventQueue();
    provider.updateSettings(numberOfTeams: 2);
    for (final name in ['Ana', 'Bob', 'Cid', 'Dan']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame();
    playToTheEnd(provider);
    expect(provider.game.scoreRevealSeen, isFalse);

    provider.markScoreRevealSeen();
    provider.restorePreValidationState();
    expect(provider.game.currentScreen, AppConstants.screenVerification);
    expect(provider.game.scoreRevealSeen, isTrue,
        reason: 'le snapshot précède la révélation');

    await provider.startGame();
    expect(provider.game.scoreRevealSeen, isFalse);
  });

  testWidgets('musique en échec ou trop lente : la révélation va au bout',
      (tester) async {
    for (final onStart in <Future<void> Function()>[
      () async => throw Exception('lecture impossible'),
      () => Completer<void>().future,
    ]) {
      final provider = await givenProvider(tester);
      playToTheEnd(provider);
      await tester.pumpWidget(app(provider, FakeSound()..onStart = onStart));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Finale'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  test('le vrai service encaisse un lecteur en échec et le fichier est livré',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(manifest.listAssets(), contains('assets/${RevealSound.musicAsset}'));

    final sound = RevealSound(); // Aucun plugin audio dans les tests.
    await sound.startMusic();
    sound.fadeOutMusic();
    sound.stopMusic();
  });

  test('l\'archive garde l\'ordre de jeu et départage comme Résultats',
      () async {
    await givenPrefs();
    givenFakePlatformPlugins();
    final provider = GameProvider();
    await pumpEventQueue();
    provider.updateSettings(numberOfTeams: 2);
    for (final name in ['Ana', 'Bob', 'Cid', 'Dan']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame();
    playToTheEnd(provider);
    await pumpEventQueue();

    final archived = (await GameHistoryService().load()).single;
    expect(archived.playOrder, [
      for (final i in provider.game.teamPlayOrder) provider.teams[i].id,
    ]);
    expect(archived.ranking.map((t) => t.id),
        provider.getTeamsSortedByScore().map((t) => t.id));
  });
}
