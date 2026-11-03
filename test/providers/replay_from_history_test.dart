import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/models/game_setup_snapshot.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

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
      'Fiesta : les règles de l\'archive passent en attente (Récap), même par '
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
    expect(provider.game.currentScreen, AppConstants.screenFiestaRecap);
  });
}
