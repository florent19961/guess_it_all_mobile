import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_result.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';

import '../helpers/test_prefs.dart';

GameResult game({
  required String id,
  Map<String, int> scores = const {'Rouge': 10, 'Bleu': 8},
  DateTime? at,
}) =>
    GameResult(
      gameId: id,
      playedAt: at ?? DateTime(2026, 1, 1),
      teams: scores.entries
          .map((e) => TeamResult(
                id: e.key.toLowerCase(),
                name: e.key,
                score: e.value,
                scoreByRound: [e.value, 0, 0],
                playerNames: ['${e.key}-1', '${e.key}-2'],
              ))
          .toList(),
      totalWords: 40,
      turnDuration: 30,
      roundsPlayed: 3,
    );

void main() {
  final history = GameHistoryService();

  group('Historique — enregistrement', () {
    test('la partie la plus récente arrive en tête', () async {
      await givenPrefs();

      await history.record(game(id: 'a'));
      await history.record(game(id: 'b'));

      final loaded = await history.load();
      expect(loaded.map((g) => g.gameId), ['b', 'a']);
    });

    test('seules les 10 dernières parties sont conservées', () async {
      // Borne DURE : sans elle, la clé grossirait indéfiniment chez un joueur
      // régulier — le défaut exact relevé sur l'historique des mots.
      await givenPrefs();

      for (var i = 0; i < 15; i++) {
        await history.record(game(id: 'g$i'));
      }

      final loaded = await history.load();
      expect(loaded, hasLength(GameHistoryService.maxEntries));
      expect(loaded.first.gameId, 'g14', reason: 'la plus récente est gardée');
      expect(loaded.last.gameId, 'g5',
          reason: 'les plus anciennes sont purgées');
    });

    test('ré-enregistrer la même partie ne la duplique pas', () async {
      // La fin de partie est atteignable plusieurs fois (retour arrière depuis
      // l'écran de résultats, reprise d'une partie suspendue).
      await givenPrefs();

      await history.record(game(id: 'a', scores: const {'Rouge': 10}));
      await history.record(game(id: 'a', scores: const {'Rouge': 12}));

      final loaded = await history.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.teams.single.score, 12,
          reason: 'c\'est le dernier enregistrement qui fait foi');
    });

    test('un aller-retour préserve scores, manches et joueurs', () async {
      await givenPrefs();
      final original = game(id: 'a', scores: const {'Rouge': 10, 'Bleu': 8});

      await history.record(original);
      final restored = (await history.load()).single;

      expect(restored.toJson(), original.toJson());
    });
  });

  group('Historique — robustesse', () {
    test('une entrée abîmée n\'efface pas les autres', () async {
      await givenPrefs();
      await history.record(game(id: 'bon'));

      // On injecte une entrée illisible à côté d'une entrée valide.
      final raw = jsonDecode((await rawString(GameHistoryService.storageKey))!)
          as Map<String, dynamic>;
      (raw['data']['entries'] as List).add({'gameId': 42});
      await givenPrefs({GameHistoryService.storageKey: jsonEncode(raw)});

      final loaded = await history.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.gameId, 'bon');
    });

    test(
        'une entrée dont `teams` n\'est pas une liste n\'efface pas les autres',
        () async {
      // 🔴 Le cas qui DÉTRUISAIT l'historique : `teams` castée en dur levait un
      // TypeError, l'exception remontait hors du `.map()` paresseux, `load()`
      // rendait vide SANS quarantaine — et le `record()` suivant réécrivait la
      // clé avec la seule partie nouvelle. Le test voisin ne l'attrapait pas :
      // son entrée fautive sortait AVANT le cast.
      await givenPrefs();
      await history.record(game(id: 'bon'));

      final raw = jsonDecode((await rawString(GameHistoryService.storageKey))!)
          as Map<String, dynamic>;
      (raw['data']['entries'] as List).add({
        'gameId': 'abime',
        'playedAt': '2026-01-01T00:00:00.000',
        'teams': <String, dynamic>{}, // un objet là où un tableau est attendu
      });
      await givenPrefs({GameHistoryService.storageKey: jsonEncode(raw)});

      final loaded = await history.load();
      expect(loaded.map((g) => g.gameId), contains('bon'),
          reason: 'la partie saine doit survivre à sa voisine abîmée');

      // Et surtout : l'archivage suivant ne doit pas l'avoir effacée.
      await history.record(game(id: 'nouvelle'));
      expect((await history.load()).map((g) => g.gameId), contains('bon'));
    });

    test('une entrée sans équipe lisible est ignorée', () async {
      Map<String, dynamic> avec(String id, Object? teams) =>
          game(id: id).toJson()..['teams'] = teams;
      await givenPrefs({
        GameHistoryService.storageKey: jsonEncode(wrapWithSchema({
          'entries': [
            game(id: 'saine').toJson(),
            avec('objet', <String, dynamic>{}),
            avec('vide', <dynamic>[]),
            avec('illisibles', [1, 'x']),
            game(id: 'absente').toJson()..remove('teams'),
          ],
        })),
      });

      final loaded = await GameHistoryService().load();
      expect(loaded.map((g) => g.gameId), ['saine']);
    });

    test('un champ au mauvais type ne coûte que son entrée', () async {
      // `as int?` levait hors de `tryFromJson` : `load()` rendait alors une liste
      // vide, et le `record()` suivant écrasait toutes les parties saines.
      await givenPrefs({
        GameHistoryService.storageKey: jsonEncode(wrapWithSchema({
          'entries': [
            game(id: 'saine').toJson(),
            game(id: 'totalWords').toJson()..['totalWords'] = 'quarante',
            game(id: 'score').toJson()
              ..['teams'] = [
                {'id': 'r', 'name': 'Rouge', 'score': 'dix'},
              ],
          ],
        })),
      });

      final loaded = await GameHistoryService().load();
      expect(loaded.map((g) => g.gameId), ['saine']);
    });

    test('un champ de liste au mauvais type ne lève pas au rendu', () async {
      // `cast<int>()` est paresseux : il passait le parsing et levait à
      // l'affichage du détail par manche.
      await givenPrefs();
      await history.record(game(id: 'bon'));

      final raw = jsonDecode((await rawString(GameHistoryService.storageKey))!)
          as Map<String, dynamic>;
      (raw['data']['entries'][0]['teams'][0]['scoreByRound'] as List)
        ..clear()
        ..addAll(['pas un entier', 3]);
      await givenPrefs({GameHistoryService.storageKey: jsonEncode(raw)});

      final restored = (await history.load()).single;
      // La lecture des éléments est le moment où l'ancien code levait.
      expect(restored.teams.first.scoreByRound.toList(), [3]);
    });

    test('un historique illisible est mis en quarantaine', () async {
      await givenPrefs({GameHistoryService.storageKey: 'pas du JSON'});

      expect(await history.load(), isEmpty);
      expect(await rawString(GameHistoryService.storageKey), isNull,
          reason: 'l\'échec ne doit pas se rejouer à chaque ouverture');
    });

    test('un historique absent rend une liste vide, sans lever', () async {
      await givenPrefs();
      expect(await history.load(), isEmpty);
    });
  });

  group('Tendances', () {
    test('sans partie, tout est à zéro', () {
      final t = computeTrends(const []);
      expect(t.gamesPlayed, 0);
      expect(t.bestScore, 0);
      expect(t.winsByTeam, isEmpty);
    });

    test('compte les victoires, le meilleur score et la moyenne', () {
      final t = computeTrends([
        game(id: 'a', scores: const {'Rouge': 10, 'Bleu': 8}),
        game(id: 'b', scores: const {'Rouge': 5, 'Bleu': 12}),
      ]);

      expect(t.gamesPlayed, 2);
      expect(t.winsByTeam, {'Rouge': 1, 'Bleu': 1});
      expect(t.bestScore, 12);
      expect(t.bestScoreTeam, 'Bleu');
      expect(t.averageScorePerGame, (10 + 8 + 5 + 12) / 2);
    });

    test('une égalité donne une victoire à CHAQUE équipe en tête', () {
      // Le jeu ne départage pas : l'historique ne doit pas inventer un
      // vainqueur.
      final t = computeTrends([
        game(id: 'a', scores: const {'Rouge': 10, 'Bleu': 10}),
      ]);

      expect(t.winsByTeam, {'Rouge': 1, 'Bleu': 1});
    });

    test('les joueurs sont classés par régularité, à ordre déterministe', () {
      final t = computeTrends([
        game(id: 'a', scores: const {'Rouge': 1}),
        game(id: 'b', scores: const {'Rouge': 1}),
        game(id: 'c', scores: const {'Bleu': 1}),
      ]);

      expect(t.playerAppearances.first.value, 2);
      // À égalité, l'ordre est alphabétique : sans ça l'affichage changerait
      // d'une ouverture à l'autre.
      final exAequo =
          t.playerAppearances.where((e) => e.value == 2).map((e) => e.key);
      expect(exAequo, ['Rouge-1', 'Rouge-2']);
    });
  });

  group('GameResult — classement', () {
    test('le classement est décroissant et le vainqueur est en tête', () {
      final g = game(id: 'a', scores: const {'Rouge': 8, 'Bleu': 12});

      expect(g.ranking.map((t) => t.name), ['Bleu', 'Rouge']);
      expect(g.winners.map((t) => t.name), ['Bleu']);
      expect(g.isTie, isFalse);
      expect(g.totalGuessed, 20);
    });

    test('une égalité est signalée comme telle', () {
      final g = game(id: 'a', scores: const {'Rouge': 9, 'Bleu': 9});

      expect(g.isTie, isTrue);
      expect(g.winners, hasLength(2));
    });

    GameResult tied(List<String>? order) => GameResult(
          gameId: 'x',
          playedAt: DateTime(2026),
          teams: const [
            TeamResult(
                id: 'r',
                name: 'Rouge',
                score: 9,
                scoreByRound: [],
                playerNames: []),
            TeamResult(
                id: 'b',
                name: 'Bleu',
                score: 9,
                scoreByRound: [],
                playerNames: []),
            TeamResult(
                id: 'v',
                name: 'Vert',
                score: 3,
                scoreByRound: [],
                playerNames: []),
          ],
          totalWords: 21,
          turnDuration: 30,
          roundsPlayed: 3,
          playOrder: order,
        );

    test('ordre de jeu connu : jamais d\'égalité, le dernier à commencer gagne',
        () {
      final g = tied(['v', 'b', 'r']);
      expect(g.ranking.map((t) => t.id), ['r', 'b', 'v']);
      expect(g.winners.map((t) => t.id), ['r']);
      expect(g.isTie, isFalse);
      final reversed = tied(['r', 'b', 'v']);
      expect(reversed.winners.map((t) => t.id), ['b']);
    });

    test('archive antérieure ou ordre incomplet : affichage inchangé', () {
      for (final order in [
        null,
        <String>['r']
      ]) {
        final g = tied(order);
        expect(g.isTie, isTrue);
        expect(g.winners.map((t) => t.id), ['r', 'b']);
        expect(g.ranking.map((t) => t.id), ['r', 'b', 'v']);
      }
    });

    test('ordre de jeu relu ; clé absente ou mal typée tolérée', () {
      final json = tied(['v', 'b', 'r']).toJson();
      expect(GameResult.tryFromJson(json)!.playOrder, ['v', 'b', 'r']);
      expect(tied(null).toJson().containsKey('playOrder'), isFalse);
      expect(GameResult.tryFromJson(tied(null).toJson())!.playOrder, isNull);
      expect(GameResult.tryFromJson({...json, 'playOrder': 'x'})!.playOrder,
          isNull);
    });

    test('statistiques : une seule victoire si l\'ordre est connu', () {
      expect(
          computeTrends([
            tied(['v', 'b', 'r'])
          ]).winsByTeam,
          {'Rouge': 1});
      expect(computeTrends([tied(null)]).winsByTeam, {'Rouge': 1, 'Bleu': 1});
    });
  });
}
