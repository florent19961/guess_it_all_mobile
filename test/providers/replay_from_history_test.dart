import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/models/game_setup_snapshot.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:guess_it_all_mobile/utils/word_categories/utils.dart';

import '../helpers/test_prefs.dart';

Future<GameProvider> givenProvider() async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

/// Équipes reconstruites, dans l'ordre : nom → noms des joueurs.
Map<String, List<String>> lineup(GameProvider p) => {
      for (final t in p.teams)
        t.name: t.playerIds.map((id) => p.getPlayerById(id)!.name).toList(),
    };

/// Joue une partie Classique jusqu'au bout : chaque manche, un tour où
/// l'équipe devine tout.
Future<void> playToTheEnd(GameProvider p) async {
  await p.startGame();
  for (var round = 0; round < 3; round++) {
    p.startTurn();
    while (p.game.remainingWords.isNotEmpty) {
      p.markWordAsGuessed();
    }
    p.endTurn();
    p.validateWords(List.of(p.game.wordsGuessedThisTurn));
    p.nextRound();
  }
  await pumpEventQueue();
}

void main() {
  test(
      '🔴 règle 7 — une archive d\'AVANT le snapshot (sans `setup`) se lit et '
      'se rejoue : équipes et joueurs, totalWords et turnDuration archivés, le '
      'reste des réglages courants, en Classique', () async {
    final provider = await givenProvider();
    provider.updateSettings(
      wordChoice: AppConstants.wordChoiceCustom,
      selectedCategories: const ['animaux'],
      passPenalty: 2,
    );

    // Forme EXACTE écrite par la version en store : ne pas « moderniser ».
    const frozen = '{"gameId":"g-old","playedAt":"2026-10-12T21:04:00.000",'
        '"teams":[{"id":"team-1","name":"Les Rouges","score":12,'
        '"scoreByRound":[5,4,3],"playerNames":["Ana","Bob"]},'
        '{"id":"team-2","name":"Les Bleus","score":9,'
        '"scoreByRound":[3,3,3],"playerNames":["Cid","Dan","Eve"]}],'
        '"totalWords":25,"turnDuration":45,"roundsPlayed":3}';
    final old = GameResult.tryFromJson(jsonDecode(frozen))!;
    expect(old.setup, isNull);

    await provider.replayFromHistory(old);

    expect(lineup(provider), {
      'Les Rouges': ['Ana', 'Bob'],
      'Les Bleus': ['Cid', 'Dan', 'Eve'],
    });
    final s = provider.settings;
    expect([s.totalWords, s.turnDuration], [25, 45]);
    expect([s.numberOfTeams, s.numberOfPlayers], [2, 5]);
    expect(s.wordChoice, AppConstants.wordChoiceCustom,
        reason: 'pas archivé : réglage courant');
    expect(s.selectedCategories, ['animaux']);
    expect(s.passPenalty, 2);
    expect(provider.pendingFiesta, isNull);
    expect(provider.game.currentScreen, AppConstants.screenSettings);

    // Snapshot bien typé mais hors bornes, et totalWords archivé hors bornes :
    // tout est écarté, les réglages courants restent.
    final corrupt = GameResult.tryFromJson({
      ...jsonDecode(frozen) as Map<String, dynamic>,
      'totalWords': 101,
      'setup': {
        'settings': {...GameSettings().toJson(), 'turnDuration': 0},
      },
    })!;
    expect(corrupt.setup, isNull);
    await provider.replayFromHistory(corrupt);
    expect([provider.settings.totalWords, provider.settings.turnDuration],
        [25, 45]);
  });

  test(
      'une partie terminée archive son snapshot ; « Rejouer » reprend joueurs, '
      'équipes et réglages, sans les mots', () async {
    final provider = await givenProvider();
    provider.updateSettings(
      numberOfPlayers: 2,
      turnDuration: 40,
      passPenalty: 3,
      wordChoice: AppConstants.wordChoiceCustom,
    );
    for (final name in ['Ana', 'Bob']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    final played = lineup(provider);
    final playedSettings = provider.settings.toJson();
    await playToTheEnd(provider);

    final archived = (await GameHistoryService().load()).single;
    expect(archived.setup!.settings.toJson(), playedSettings);

    // On repart d'ailleurs : réglages changés, joueurs effacés.
    await provider.startNewGame();
    provider.updateSettings(turnDuration: 90, passPenalty: 0);

    await provider.replayFromHistory(archived);

    expect(lineup(provider), played);
    expect(provider.settings.toJson(), playedSettings);
    expect(provider.players.every((p) => p.words.isEmpty), isTrue);
    expect(provider.pendingFiesta, isNull);
    expect(provider.game.currentScreen, AppConstants.screenSettings);
  });

  test(
      'Fiesta : les règles de l\'archive passent en attente (Paramètres), même par '
      'dessus une partie suspendue', () async {
    final provider = await givenProvider();
    for (final name in ['X', 'Y']) {
      final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
    await provider.suspendGame();

    final rules = FiestaRules(
      mode: FiestaMode.custom,
      ensembleName: 'Soirée',
      drawCount: 2,
    );
    final entry = GameResult(
      gameId: 'g-fiesta',
      playedAt: DateTime(2026, 11, 1),
      teams: const [
        TeamResult(
            id: 'team-1',
            name: 'A',
            score: 1,
            scoreByRound: [1, 0, 0],
            playerNames: ['Ana']),
        TeamResult(
            id: 'team-2',
            name: 'B',
            score: 0,
            scoreByRound: [0, 0, 0],
            playerNames: ['Bob']),
      ],
      totalWords: 2,
      turnDuration: 30,
      roundsPlayed: 3,
      mode: 'fiesta_custom',
      setup: GameSetupSnapshot(settings: GameSettings(), fiesta: rules),
    );
    final back = GameResult.tryFromJson(jsonDecode(jsonEncode(entry)))!;

    await provider.replayFromHistory(back);

    expect(lineup(provider), {
      'A': ['Ana'],
      'B': ['Bob'],
    });
    expect(provider.pendingFiesta!.toJson(), rules.toJson());
    expect(provider.game.isGameSuspended, isFalse);
    expect(provider.game.currentScreen, AppConstants.screenSettings);

    // Aléatoire (réglage de l'archive) : l'écran des mots reste fermé.
    provider.goToScreen(AppConstants.screenWords);
    expect(provider.game.currentScreen, AppConstants.screenSettings);
  });

  test(
      'Auto / Personnalisé : rejouer une Fiesta l\'aligne, rejouer du Classique '
      'n\'y touche pas', () async {
    GameResult archive(FiestaRules? fiesta) => GameResult(
          gameId: 'g',
          playedAt: DateTime(2026, 11, 1),
          teams: const [
            TeamResult(
                id: 'team-1',
                name: 'A',
                score: 0,
                scoreByRound: [0, 0, 0],
                playerNames: ['Ana']),
            TeamResult(
                id: 'team-2',
                name: 'B',
                score: 0,
                scoreByRound: [0, 0, 0],
                playerNames: ['Bob']),
          ],
          totalWords: 2,
          turnDuration: 30,
          roundsPlayed: 3,
          setup: GameSetupSnapshot(settings: GameSettings(), fiesta: fiesta),
        );
    final provider = await givenProvider();

    provider.updateSettings(fiestaMode: FiestaMode.custom);
    await provider.replayFromHistory(archive(null));
    expect(provider.settings.fiestaMode, FiestaMode.custom);

    await provider
        .replayFromHistory(archive(FiestaRules(mode: FiestaMode.auto)));
    expect(provider.settings.fiestaMode, FiestaMode.auto);
  });

  test(
      'rejouer par-dessus une partie suspendue la clôt UNE fois : historique '
      'des mots incrémenté une fois, plus de tracking en cours', () async {
    final provider = await givenProvider();
    await WordHistoryService().initialize();
    await WordHistoryService().clearHistory();
    AnalyticsService().forgetCurrentGame();
    final words = await generateWordsFromCategoriesAsync(['nature'], 2);
    for (var i = 0; i < 2; i++) {
      final id = (provider.addPlayer('J$i')['player'] as dynamic).id as String;
      provider.updatePlayerWords(id, [words[i]]);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame();
    await provider.suspendGame();
    final archived = GameResult.tryFromJson(jsonDecode(
        '{"gameId":"g","playedAt":"2026-10-12T21:04:00.000","teams":'
        '[{"name":"A","playerNames":["Ana"]},{"name":"B","playerNames":["Bob"]}],'
        '"totalWords":25,"turnDuration":45,"roundsPlayed":3}'))!;

    await provider.replayFromHistory(archived);
    await provider.replayFromHistory(archived);

    expect(AnalyticsService().isTracking, isFalse);
    for (final w in words) {
      expect(WordHistoryService().getSeenCount(w), 1, reason: w);
    }
  });

  group('config rejouée, app tuée avant le lancement', () {
    GameResult archive(FiestaRules fiesta) => GameResult(
          gameId: 'g',
          playedAt: DateTime(2026, 11, 1),
          teams: const [
            TeamResult(
                id: 'team-1',
                name: 'A',
                score: 1,
                scoreByRound: [1, 0, 0],
                playerNames: ['Ana']),
            TeamResult(
                id: 'team-2',
                name: 'B',
                score: 0,
                scoreByRound: [0, 0, 0],
                playerNames: ['Bob']),
          ],
          totalWords: 2,
          turnDuration: 30,
          roundsPlayed: 3,
          mode: 'fiesta_custom',
          setup: GameSetupSnapshot(settings: GameSettings(), fiesta: fiesta),
        );

    Future<GameProvider> reopen() async {
      final provider = GameProvider();
      await pumpEventQueue();
      return provider;
    }

    /// Ensembles « Soirée A » et « Soirée B », B utilisé en dernier.
    Future<(FiestaRules, FiestaRules)> givenEnsembles() async {
      final service = FiestaEnsembleService();
      final a = await service.create(defaultEnsembleRules('Soirée A'));
      final b = await service
          .create(defaultEnsembleRules('Soirée B').copyWith(drawCount: 2));
      await service.markUsed(b!.id);
      return (a!.rules, b.rules);
    }

    test(
        'l\'archive survit au kill et au « Rejouer » de l\'accueil, sans '
        'céder au dernier ensemble', () async {
      final provider = await givenProvider();
      final (a, _) = await givenEnsembles();
      await provider.replayFromHistory(archive(a));
      await pumpEventQueue();

      final reopened = await reopen();
      expect(reopened.pendingFiesta?.ensembleName, 'Soirée A');
      expect(reopened.pendingFiesta?.toJson(), a.toJson());

      await reopened.restartWithSamePlayers();
      await pumpEventQueue();
      expect((await reopen()).pendingFiesta?.ensembleName, 'Soirée A');
    });

    test('un choix explicite d\'ensemble ou de mode l\'efface', () async {
      final provider = await givenProvider();
      final (a, b) = await givenEnsembles();

      await provider.replayFromHistory(archive(a));
      provider.setPendingFiesta(b);
      await pumpEventQueue();
      expect((await reopen()).pendingFiesta?.ensembleName, 'Soirée B');

      await provider.replayFromHistory(archive(a));
      provider.setPendingFiesta(FiestaRules(mode: FiestaMode.auto));
      await pumpEventQueue();
      expect((await reopen()).pendingFiesta?.mode, FiestaMode.auto);

      await provider.replayFromHistory(archive(a));
      provider.setPendingFiesta(null);
      await pumpEventQueue();
      expect((await reopen()).pendingFiesta, isNull);
    });

    test('le lancement l\'efface', () async {
      final provider = await givenProvider();
      final (a, _) = await givenEnsembles();
      await provider.replayFromHistory(archive(a));
      for (final player in provider.players) {
        provider.updatePlayerWords(player.id, ['mot-${player.name}']);
      }
      await provider.startGame(fiesta: provider.pendingFiesta);
      await pumpEventQueue();

      final disk = await persistedData(AppConstants.settingsKey);
      expect(disk!.containsKey('replayFiesta'), isFalse);
    });

    test('relecture tolérante : illisible = le dernier ensemble', () {
      expect(GameSettings.fromJson(const {'replayFiesta': 'x'}).replayFiesta,
          isNull);
      expect(
          GameSettings.fromJson(const {
            'replayFiesta': {'format': 2}
          }).replayFiesta,
          isNull);
      expect(GameSettings.fromJson(const {}).replayFiesta, isNull);
    });
  });
}
