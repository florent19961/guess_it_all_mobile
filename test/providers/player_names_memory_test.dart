import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/models/player.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/players_screen.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

const _start = ['Ana', 'Bob', 'Cid', 'Dan'];

Future<GameProvider> newProvider(WidgetTester tester, {int players = 4}) async {
  final provider = GameProvider();
  await tester.runAsync(() => pumpEventQueue());
  provider.updateSettings(
    numberOfPlayers: players,
    wordChoice: AppConstants.wordChoiceCustom,
  );
  return provider;
}

/// L'écran Joueurs, monté à neuf comme à chaque arrivée sur l'écran.
Future<void> openPlayers(WidgetTester tester, GameProvider provider) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
    value: provider,
    child: const MaterialApp(home: Scaffold(body: PlayersScreen())),
  ));
  await tester.pump();
  await tester.runAsync(() => pumpEventQueue());
  await tester.pump();
  await tester.pump();
}

/// Ce que montrent les champs, pas seulement le modèle.
List<String> fields(WidgetTester tester) => tester
    .widgetList<TextField>(find.byType(TextField))
    .map((f) => f.controller!.text)
    .toList();

Future<void> type(WidgetTester tester, List<String> names) async {
  for (final (i, name) in names.indexed) {
    await tester.enterText(find.byType(TextField).at(i), name);
    await tester.pump();
  }
}

Future<void> flushWrites(WidgetTester tester) =>
    tester.runAsync(() => pumpEventQueue()).then((_) {});

void main() {
  setUp(() async {
    await givenPrefs();
    givenFakePlatformPlugins();
  });

  Future<GameProvider> seeded(WidgetTester tester) async {
    final provider = await newProvider(tester);
    await openPlayers(tester, provider);
    await type(tester, _start);
    return provider;
  }

  testWidgets('« Jouer » / « Nouvelle partie » : les noms restent',
      (tester) async {
    final provider = await seeded(tester);
    await tester.runAsync(provider.startNewGame);
    expect(provider.players, isEmpty,
        reason: 'nouvelle partie = joueurs neufs');
    await openPlayers(tester, provider);
    expect(fields(tester), _start);
  });

  testWidgets('kill de l\'app puis nouvelle partie : les noms restent',
      (tester) async {
    final provider = await seeded(tester);
    await tester.runAsync(provider.startNewGame);
    await flushWrites(tester);
    final reopened = await newProvider(tester);
    await openPlayers(tester, reopened);
    expect(fields(tester), _start);
  });

  testWidgets('kill sur l\'écran Joueurs, en pleine saisie : les noms restent',
      (tester) async {
    await seeded(tester);
    await flushWrites(tester);
    final reopened = await newProvider(tester);
    await tester.runAsync(reopened.startNewGame);
    await openPlayers(tester, reopened);
    expect(fields(tester), _start);
  });

  testWidgets('« Réinitialiser les paramètres » : les noms restent',
      (tester) async {
    final provider = await seeded(tester);
    await tester.runAsync(provider.clearLocalStorage);
    provider.updateSettings(wordChoice: AppConstants.wordChoiceCustom);
    await openPlayers(tester, provider);
    expect(fields(tester).take(4), _start,
        reason: 'le nombre de joueurs, lui, revient à sa valeur par défaut');
  });

  testWidgets('aller-retour par les Paramètres et changement de mode',
      (tester) async {
    final provider = await seeded(tester);
    provider.goToScreen(AppConstants.screenSettings);
    provider.updateSettings(wordChoice: AppConstants.wordChoiceRandom);
    provider.updateSettings(wordChoice: AppConstants.wordChoiceCustom);
    await openPlayers(tester, provider);
    expect(fields(tester), _start);
  });

  testWidgets('moins de joueurs puis plus : les noms mis de côté reviennent',
      (tester) async {
    final provider = await newProvider(tester, players: 6);
    await openPlayers(tester, provider);
    const six = [..._start, 'Eve', 'Fay'];
    await type(tester, six);

    provider.updateSettings(numberOfPlayers: 4);
    await openPlayers(tester, provider);
    expect(fields(tester), _start);

    provider.updateSettings(numberOfPlayers: 6);
    await openPlayers(tester, provider);
    expect(fields(tester), six);
  });

  testWidgets(
      'effacer un nom à la main le retire, y compris après nouvelle partie et '
      'kill ; les autres gardent leur place', (tester) async {
    final provider = await seeded(tester);
    await type(tester, ['Ana', '', 'Cid', 'Dan']);

    await openPlayers(tester, provider);
    expect(fields(tester), ['Ana', '', 'Cid', 'Dan'],
        reason: 'aller-retour : rien ne le remplit à nouveau');

    await tester.runAsync(provider.startNewGame);
    await flushWrites(tester);
    final reopened = await newProvider(tester);
    await openPlayers(tester, reopened);
    expect(fields(tester), ['Ana', 'Cid', 'Dan', '']);
  });

  testWidgets('tout effacer laisse la liste vide pour de bon', (tester) async {
    final provider = await seeded(tester);
    await type(tester, ['', '', '', '']);
    await tester.runAsync(provider.startNewGame);
    await openPlayers(tester, provider);
    expect(fields(tester), ['', '', '', '']);
  });

  testWidgets('corriger un nom le remplace, sans laisser l\'ancien',
      (tester) async {
    final provider = await seeded(tester);
    await type(tester, ['Ana', 'Bobby', 'Cid', 'Dan']);
    await tester.runAsync(provider.startNewGame);
    await openPlayers(tester, provider);
    expect(fields(tester), ['Ana', 'Bobby', 'Cid', 'Dan']);
  });

  testWidgets('un doublon le temps d\'une saisie ne perd pas le premier nom',
      (tester) async {
    final provider = await seeded(tester);
    await type(tester, ['Ana', 'Ana', 'Cid', 'Dan']);
    await type(tester, ['Ana', 'Bea', 'Cid', 'Dan']);
    await tester.runAsync(provider.startNewGame);
    await openPlayers(tester, provider);
    expect(fields(tester), ['Ana', 'Bea', 'Cid', 'Dan']);
  });

  test(
      '🔴 règle 7 — téléphone venu de la version en store : les noms de sa '
      'session (sans la nouvelle clé) sont repris', () async {
    await givenPrefs({
      AppConstants.gameSessionKey: jsonEncode(wrapWithSchema({
        'players': [
          for (final name in _start) Player.create(name).toJson(),
          Player.create('').toJson(),
        ],
        'teams': const [],
      })),
    });
    final provider = GameProvider();
    await pumpEventQueue();
    await provider.startNewGame();
    expect(provider.nextSavedName, 'Ana');

    final reopened = GameProvider();
    await pumpEventQueue();
    expect(reopened.nextSavedName, 'Ana', reason: 'écrit sur disque');
  });

  test('« Rejouer » : mêmes joueurs, mêmes équipes, mots effacés', () async {
    final provider = GameProvider();
    await pumpEventQueue();
    for (final name in _start) {
      final id = (provider.addPlayer(name)['player'] as Player).id;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    final teams = provider.teams.map((t) => t.playerIds).toList();

    await provider.restartWithSamePlayers();

    expect(provider.players.map((p) => p.name), _start);
    expect(provider.players.every((p) => p.words.isEmpty), isTrue);
    expect(provider.teams.map((t) => t.playerIds), teams);
  });

  test(
      '« Rejouer » depuis l\'historique : les joueurs de l\'archive d\'abord, '
      'les autres noms restent en réserve', () async {
    final provider = GameProvider();
    await pumpEventQueue();
    for (final name in _start) {
      provider.addPlayer(name);
    }
    final archive = GameResult.tryFromJson(jsonDecode(
        '{"gameId":"g","playedAt":"2026-10-12T21:04:00.000","teams":['
        '{"id":"a","name":"Rouges","score":1,"scoreByRound":[1,0,0],'
        '"playerNames":["Zoe","Yan"]},'
        '{"id":"b","name":"Bleus","score":0,"scoreByRound":[0,0,0],'
        '"playerNames":["Xav","Ana"]}],'
        '"totalWords":20,"turnDuration":45,"roundsPlayed":3}'))!;

    await provider.replayFromHistory(archive);
    expect(provider.players.map((p) => p.name), ['Zoe', 'Yan', 'Xav', 'Ana']);
    expect(provider.teams.first.playerIds.length, 2);
    expect(provider.nextSavedName, 'Bob',
        reason: 'un joueur de plus : le premier nom pas encore à la table');

    await provider.startNewGame();
    final order = <String>[];
    for (var i = 0; i < 6; i++) {
      order.add(provider.nextSavedName!);
      provider.addPlayer(order.last);
    }
    expect(order, ['Zoe', 'Yan', 'Xav', 'Ana', 'Bob', 'Cid']);
  });

  test('partie suspendue : joueurs et équipes repris tels quels après un kill',
      () async {
    final provider = GameProvider();
    await pumpEventQueue();
    for (final name in _start) {
      final id = (provider.addPlayer(name)['player'] as Player).id;
      provider.updatePlayerWords(id, ['mot-$name']);
    }
    provider.createTeams();
    provider.randomizeTeams();
    await provider.startGame();
    final teams = provider.teams.map((t) => t.playerIds).toList();
    await provider.suspendGame();
    await pumpEventQueue();

    final reopened = GameProvider();
    await pumpEventQueue();
    expect(reopened.game.isGameSuspended, isTrue);
    expect(reopened.players.map((p) => p.name), _start);
    expect(reopened.teams.map((t) => t.playerIds), teams);
    expect(reopened.players.every((p) => p.words.isNotEmpty), isTrue);
  });
}
