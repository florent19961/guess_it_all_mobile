import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/surprise_challenge.dart';

void main() {
  group('trailingTeams', () {
    test('rend les 2 équipes les plus en retard, la dernière d\'abord', () {
      expect(trailingTeams({'a': 30, 'b': 12, 'c': 20, 'd': 25}), ['b', 'c']);
    });

    test('à 2 équipes, rend les deux', () {
      expect(trailingTeams({'a': 30, 'b': 12}), ['b', 'a']);
    });

    test('à score égal, garde l\'ordre des équipes', () {
      expect(trailingTeams({'a': 10, 'b': 5, 'c': 5}), ['b', 'c']);
      expect(trailingTeams({'a': 7, 'b': 7, 'c': 7}), ['a', 'b']);
    });
  });

  group('slowestPlayer', () {
    test('rend le moins de mots par seconde, sur tous ses tours', () {
      expect(
        slowestPlayer(
          roster: ['ana', 'leo'],
          turns: const [
            TurnPace(playerId: 'ana', words: 3, seconds: 30),
            TurnPace(playerId: 'ana', words: 3, seconds: 30),
            TurnPace(playerId: 'leo', words: 5, seconds: 30),
          ],
        ),
        'ana',
      );
    });

    test('un tour sans mot compte dans le temps', () {
      expect(
        slowestPlayer(
          roster: ['ana', 'leo'],
          turns: const [
            TurnPace(playerId: 'ana', words: 4, seconds: 30),
            TurnPace(playerId: 'ana', words: 0, seconds: 30),
            TurnPace(playerId: 'leo', words: 3, seconds: 30),
          ],
        ),
        'ana',
      );
    });

    test('à égalité exacte, garde l\'ordre de l\'équipe', () {
      expect(
        slowestPlayer(
          roster: ['leo', 'ana'],
          turns: const [
            TurnPace(playerId: 'ana', words: 1, seconds: 3),
            TurnPace(playerId: 'leo', words: 10, seconds: 30),
          ],
        ),
        'leo',
      );
    });

    test('un joueur sans temps de jeu n\'est pas mesuré', () {
      expect(
        slowestPlayer(
          roster: ['sam', 'ana', 'leo'],
          turns: const [
            TurnPace(playerId: 'sam', words: 0, seconds: 0),
            TurnPace(playerId: 'ana', words: 5, seconds: 30),
            TurnPace(playerId: 'leo', words: 2, seconds: 30),
          ],
        ),
        'leo',
      );
    });

    test('sans aucune mesure, rend le premier de l\'équipe', () {
      expect(slowestPlayer(roster: ['sam', 'ana'], turns: const []), 'sam');
    });

    test('ignore les joueurs d\'une autre équipe', () {
      expect(
        slowestPlayer(
          roster: ['ana', 'leo'],
          turns: const [
            TurnPace(playerId: 'bob', words: 0, seconds: 60),
            TurnPace(playerId: 'ana', words: 5, seconds: 30),
            TurnPace(playerId: 'leo', words: 6, seconds: 30),
          ],
        ),
        'ana',
      );
    });
  });

  group('drawChallengeSchedule', () {
    final schedules = [
      for (var i = 0; i < 200; i++) drawChallengeSchedule('game-$i'),
    ];

    test('même partie, même tirage', () {
      for (var i = 0; i < 200; i++) {
        expect(drawChallengeSchedule('game-$i'), schedules[i]);
      }
    });

    test('1 ou 2 défis, seulement après les manches 1 et 2', () {
      for (final schedule in schedules) {
        expect(schedule.length, inInclusiveRange(1, 2));
        expect({1, 2}.containsAll(schedule.keys), isTrue);
      }
    });

    test('deux défis d\'une même partie sont différents', () {
      for (final schedule in schedules.where((s) => s.length == 2)) {
        expect(schedule[1], isNot(schedule[2]));
      }
    });

    test('tous les cas sortent : 1 ou 2 défis, chaque manche, chaque défi', () {
      expect(schedules.map((s) => s.length).toSet(), {1, 2});
      final solo = schedules.where((s) => s.length == 1);
      expect(solo.map((s) => s.keys.single).toSet(), {1, 2});
      expect(
        schedules.expand((s) => s.values).toSet(),
        SurpriseChallenge.values.toSet(),
      );
    });
  });

  group('pickGuessedWord', () {
    const words = ['Lion', 'Tigre', 'Ours', 'Loup', 'Renard', 'Aigle'];

    test('même partie, même manche, même mot, quel que soit l\'ordre', () {
      final first = pickGuessedWord(
        gameId: 'g',
        finishedRound: 1,
        guessedWords: words,
      );
      final shuffled = pickGuessedWord(
        gameId: 'g',
        finishedRound: 1,
        guessedWords: words.reversed.toList(),
      );
      expect(words, contains(first));
      expect(shuffled, first);
    });

    test('un doublon ne change pas le mot choisi', () {
      expect(
        pickGuessedWord(
          gameId: 'g',
          finishedRound: 2,
          guessedWords: [...words, ...words],
        ),
        pickGuessedWord(gameId: 'g', finishedRound: 2, guessedWords: words),
      );
    });

    test('dépend de la partie et de la manche', () {
      final picked = {
        for (var i = 0; i < 50; i++)
          pickGuessedWord(
            gameId: 'g$i',
            finishedRound: i.isEven ? 1 : 2,
            guessedWords: words,
          ),
      };
      expect(picked.length, greaterThan(1));
    });

    test('aucun mot deviné : null', () {
      expect(
        pickGuessedWord(gameId: 'g', finishedRound: 1, guessedWords: const []),
        isNull,
      );
    });
  });

  group('catalogue', () {
    test('les 5 défis ont un titre et une règle', () {
      expect(SurpriseChallenge.values.map((c) => c.title), [
        'Bras de fer chinois',
        'La chaise',
        'Téléphone arabe de mime',
        'Chifoumi en 1 point',
        'Taper dans ses mains 10 s',
      ]);
      for (final challenge in SurpriseChallenge.values) {
        expect(challenge.rule('Ana', 'Bob'), isNotEmpty);
      }
    });

    test('le téléphone arabe nomme les deux joueurs', () {
      final rule = SurpriseChallenge.mimeRelay.rule('Ana', 'Bob');
      expect(rule, startsWith('Ana et Bob découvrent un mot déjà joué.'));
    });
  });
}
