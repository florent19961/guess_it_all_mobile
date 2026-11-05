import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_recap.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/models/word_event.dart';
import 'package:guess_it_all_mobile/models/word_stats.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';

import '../helpers/test_prefs.dart';

/// Story 2-7 : les modificateurs Fiesta dans les analytics et l'historique.
/// Règle 7 : tout ce que la version en store a écrit se relit, et une partie
/// Classique écrit exactement l'ancienne forme (le document Firestore est
/// `GameAnalytics.toJson()` tel quel).

const _newAnalyticsKeys = ['gameMode', 'fiestaRules'];

Future<void> _start(AnalyticsService a, String id, {bool fiesta = false}) =>
    a.startGame(
      gameId: id,
      numberOfPlayers: 4,
      numberOfTeams: 2,
      totalWords: 2,
      turnDuration: 30,
      selectedCategories: const ['nature'],
      selectedDifficultyLevels: const [1],
      wordMetadata: const {
        'chat': WordMetadata(word: 'chat', categoryId: 'nature', difficulty: 1),
        'chien':
            WordMetadata(word: 'chien', categoryId: 'nature', difficulty: 1),
      },
      gameMode: fiesta ? 'fiesta_custom' : null,
      fiestaRules: fiesta ? const {'mode': 'auto'} : null,
    );

WordEventContext _ctx([List<String>? modifiers]) =>
    (round: 2, turn: 3, teamId: 't1', playerId: 'p1', modifiers: modifiers);

void _show(AnalyticsService a, String word, {List<String>? modifiers}) =>
    a.onWordShown(word, _ctx(modifiers));

/// Blob `guessItAll_analytics_<id>` tel que l'écrit la version en store :
/// ni `gameMode`, ni `fiestaRules`, ni `modifiers` sur les events. Partie non
/// terminée (orpheline).
Map<String, dynamic> _storeBlob(String id) => {
      'gameId': id,
      'userId': 'u',
      'appVersion': '1.0.0',
      'platform': 'android',
      'locale': 'fr',
      'deviceModel': null,
      'startedAt': '2026-10-01T20:00:00.000',
      'endedAt': null,
      'numberOfPlayers': 4,
      'numberOfTeams': 2,
      'totalWords': 1,
      'turnDuration': 30,
      'selectedCategories': ['nature'],
      'selectedDifficultyLevels': [1],
      'events': [
        for (final type in ['shown', 'guessed'])
          {
            'eventId': 'e-$type',
            'word': 'chat',
            'eventType': type,
            'timestamp': 1000,
            'round': 1,
            'turn': 1,
            'teamId': 't1',
            'playerId': 'p1',
            'gameId': id,
            'durationMs': type == 'shown' ? null : 500,
          },
      ],
      'wordMetadata': {
        'chat': {'word': 'chat', 'categoryId': 'nature', 'difficulty': 1},
      },
      'wordStats': <String, dynamic>{},
    };

void main() {
  late AnalyticsService analytics;

  setUp(() async {
    await givenPrefs();
    givenFakePlatformPlugins();
    analytics = AnalyticsService();
    analytics.forgetCurrentGame();
  });

  test('un blob analytics de la version en store se relit et se finalise',
      () async {
    await givenPrefs({
      'guessItAll_analytics_index': jsonEncode(['old']),
      'guessItAll_analytics_old': jsonEncode(_storeBlob('old')),
    });

    final loaded = await analytics.loadAllGames();
    expect(loaded.single.events, hasLength(2));
    expect(loaded.single.gameMode, isNull);
    expect(loaded.single.events.every((e) => e.modifiers == null), isTrue);

    expect(await analytics.finalizeOrphanedGames(), 1);
    final rewritten = jsonDecode((await rawString('guessItAll_analytics_old'))!)
        as Map<String, dynamic>;
    expect(rewritten['endedAt'], isNotNull);
    expect((await analytics.loadGameAnalytics('old'))!.wordStats['chat'],
        isNotNull,
        reason: 'le mot compte dans les stats comme avant');
    // Relue puis réécrite : toujours aucune clé nouvelle.
    expect(rewritten.keys, isNot(contains(anyOf(_newAnalyticsKeys))));
    expect((rewritten['events'] as List).cast<Map>().first.keys,
        isNot(contains('modifiers')));
  });

  test('une partie Classique n\'écrit aucune clé nouvelle (Firestore compris)',
      () async {
    await _start(analytics, 'classic');
    _show(analytics, 'chat');
    analytics.onWordGuessed('chat', _ctx());
    analytics.onWordInvalidated('chat', _ctx());

    // `toJson()` est exactement le document envoyé à Firestore.
    final json = analytics.currentGame!.toJson();
    expect(json.keys, isNot(contains(anyOf(_newAnalyticsKeys))));
    for (final e in json['events'] as List) {
      expect((e as Map).keys, isNot(contains('modifiers')));
    }
  });

  test(
      'Fiesta : shown, guessed et invalidated portent les modificateurs, '
      'y compris après un kill, et survivent à la relecture', () async {
    await _start(analytics, 'fiesta', fiesta: true);
    _show(analytics, 'chat', modifiers: ['minus_10s']);
    analytics.onWordGuessed('chat', _ctx(['minus_10s']));
    // Vérification après le tour : contexte fourni par l'appelant.
    analytics.onWordInvalidated('chat', _ctx(['minus_10s']));
    await analytics.saveCurrentGame();

    // Kill : la mémoire est perdue, le disque reste. Le mot suivant est
    // ré-étiqueté par l'appelant depuis l'état persisté de la partie.
    analytics.forgetCurrentGame();
    expect(await analytics.resumeGame('fiesta'), isTrue);
    _show(analytics, 'chien', modifiers: ['minus_10s']);
    analytics.onWordPassed('chien', _ctx(['minus_10s']));
    await analytics.saveCurrentGame();

    final reread = (await analytics.loadGameAnalytics('fiesta'))!;
    expect(reread.gameMode, 'fiesta_custom');
    expect(reread.fiestaRules, {'mode': 'auto'});
    expect(reread.events.map((e) => e.eventType), [
      WordEventType.shown,
      WordEventType.guessed,
      WordEventType.invalidated,
      WordEventType.shown,
      WordEventType.passed,
    ]);
    for (final e in reread.events) {
      expect(e.modifiers, ['minus_10s'], reason: '${e.eventType}');
    }
  });

  group('GameResult (historique)', () {
    test('une entrée de la version en store se relit, sans mode', () {
      final legacy = GameResult.tryFromJson({
        'gameId': 'old',
        'playedAt': '2026-10-01T20:00:00.000',
        'teams': [
          {'id': 'r', 'name': 'Rouge'},
        ],
        'totalWords': 40,
        'turnDuration': 30,
        'roundsPlayed': 3,
      })!;
      expect(legacy.mode, isNull);
      expect(legacy.modifierRecap, isNull);
      expect(legacy.toJson().keys,
          isNot(contains(anyOf('mode', 'modifierRecap'))));
    });

    test('une partie Fiesta archive son mode et son récap, en faits', () {
      final result = GameResult(
        gameId: 'f',
        playedAt: DateTime(2026, 11, 3),
        teams: const [
          TeamResult(
              id: 'r',
              name: 'Rouge',
              score: 0,
              scoreByRound: [0, 0, 0],
              playerNames: []),
        ],
        totalWords: 40,
        turnDuration: 30,
        roundsPlayed: 3,
        mode: 'fiesta_custom',
        modifierRecap: const [
          ModifierRecapItem(RecapKind.boost,
              round: 2, catalogId: 'plus_10s', teamId: 'bleue'),
          ModifierRecapItem(RecapKind.bonusUsed,
              round: 3,
              catalogId: 'block_guesser',
              teamId: 'rouge',
              chooserId: 'bleue'),
        ],
      );
      final json = jsonEncode(result.toJson());
      final reread = GameResult.tryFromJson(jsonDecode(json))!;
      expect(reread.mode, 'fiesta_custom');
      // Archivé en faits (ids), jamais en phrases (epic fix B5).
      expect(jsonEncode(reread.toJson()), json);
      expect(json, isNot(contains('Coup de pouce')));
    });

    test(
        'une partie archivée avant Fiesta v3 se relit : faits de genres retirés '
        '(`catchUp`, `choice`) ignorés seuls', () {
      final reread = GameResult.tryFromJson(jsonDecode('{"gameId":"old",'
          '"playedAt":"2026-11-03T20:00:00.000","teams":[{"id":"r","name":"Rouge"}],"totalWords":40,'
          '"turnDuration":30,"roundsPlayed":3,"mode":"fiesta_custom",'
          '"modifierRecap":[{"kind":"catchUp","round":2,"teamId":"b",'
          '"seconds":18},{"kind":"choice","round":3,"catalogId":"block_guesser",'
          '"teamId":"r","chooserId":"b"},{"kind":"draw","round":1,'
          '"catalogId":"no_pass"},{"kind":"boost","round":2,'
          '"catalogId":"free_pass","teamId":"b"}]}'))!;
      expect(reread.modifierRecap!.map((i) => i.kind),
          [RecapKind.draw, RecapKind.boost]);
      expect(
          formatModifierRecap(reread.modifierRecap!,
              teamNames: const {'b': 'Bleue'}).map((l) => l.title),
          contains('Cartouches au hasard'));
    });
  });
}
