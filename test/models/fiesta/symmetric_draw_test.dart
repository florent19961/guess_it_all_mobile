import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/challenge_plan.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_recap.dart';
import 'package:guess_it_all_mobile/models/fiesta/round_transition.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

Set<String> ids(Iterable<dynamic> instances) =>
    {for (final m in instances) m.catalogId as String};

FiestaRules drawing(Set<String> draw, {int count = 1}) => FiestaRules(
      drawCount: count,
      modifiers: {for (final id in draw) id: const ModifierSetting(draw: true)},
    );

void main() {
  test('la graine est stable et distingue la manche', () {
    expect(drawSeed('g', 1), drawSeed('g', 1));
    expect(drawSeed('g', 1), isNot(drawSeed('g', 2)));
  });

  test('Toujours et aléatoire : toutes les manches où il existe', () {
    final rules = FiestaRules(modifiers: const {
      'one_answer': ModifierSetting(always: true),
      'draw': ModifierSetting(always: true),
      'other_language': ModifierSetting(always: true),
    });
    expect(ids(alwaysForRound(rules, 1)), {'one_answer', 'other_language'});
    expect(ids(alwaysForRound(rules, 2)), {'one_answer', 'other_language'});
    expect(ids(alwaysForRound(rules, 3)), {'one_answer', 'draw'});

    expect(
        ids(roundModifiers(drawing({'mime_no_arms'}), gameId: 'g', round: 1)),
        isEmpty);
    expect(
        ids(roundModifiers(drawing({'mime_no_arms'}), gameId: 'g', round: 3)),
        {'mime_no_arms'});
    expect(
        ids(roundModifiers(drawing({'other_language'}), gameId: 'g', round: 3)),
        isEmpty);
  });

  test('un modificateur peut être en aléatoire ET en cartouche', () {
    final rules = FiestaRules(drawCount: 1, modifiers: const {
      'reversed': ModifierSetting(draw: true, charges: 2),
    });
    expect(ids(roundModifiers(rules, gameId: 'g', round: 1)), {'reversed'});
    expect(rules.chargesOf('reversed'), 2);
  });

  test('tirage : déterministe, le verrouillé ne sort jamais, 0 = aucun', () {
    final rules = FiestaRules(drawCount: 2, modifiers: const {
      'no_pass': ModifierSetting(always: true, draw: true),
      'reversed': ModifierSetting(draw: true),
      'one_answer': ModifierSetting(draw: true),
    });
    final one = roundModifiers(rules, gameId: 'g', round: 1);
    expect(ids(one), {'no_pass', 'reversed', 'one_answer'},
        reason: 'no_pass une seule fois, en Toujours');
    expect(ids(roundModifiers(rules, gameId: 'g', round: 1)), ids(one));
    expect(
        drawForRound(
            rules: drawing({'reversed'}, count: 0),
            round: 1,
            already: const [],
            random: Random(1)),
        isEmpty);
  });

  test('moins de candidats que demandé : on en tire moins', () {
    expect(
        roundModifiers(drawing({'reversed'}, count: 5), gameId: 'g', round: 1),
        hasLength(1));
  });

  test('les mimes s\'excluent au tirage, sauf Bruitages et drap', () {
    for (var i = 0; i < 40; i++) {
      final drawn = ids(roundModifiers(
          drawing({'mime_no_arms', 'mime_eyes_closed'}, count: 2),
          gameId: 'g$i',
          round: 3));
      expect(drawn, hasLength(1));
      expect(
          ids(roundModifiers(
              drawing({'sounds_only', 'mime_under_sheet'}, count: 2),
              gameId: 'g$i',
              round: 3)),
          hasLength(2));
    }
  });

  test('un seul lieu de vérité pour la paire Bruitages / drap', () {
    expect(areCompatible('sounds_only', 'mime_under_sheet'), isTrue);
    expect(areCompatible('mime_under_sheet', 'sounds_only'), isTrue);
    expect(areCompatible('sounds_only', 'mime_no_arms'), isFalse);
    expect(areCompatible('mime_back_turned', 'mime_under_sheet'), isFalse);
    expect(modifierDescription('sounds_only', ['mime_under_sheet']),
        'Gestes et bruits sous le drap, sans parler.');
    expect(modifierDescription('mime_under_sheet', ['sounds_only']),
        'Gestes et bruits sous le drap, sans parler.');
    expect(modifierDescription('sounds_only', const []),
        modifierById('sounds_only')!.description);
  });

  group('tirage sans remise au fil de la partie', () {
    const seeds = 200;

    List<String> round(FiestaRules rules, String gameId, int r) => [
          for (final m in roundModifiers(rules, gameId: gameId, round: r))
            m.catalogId
        ];

    test('vivier suffisant : aucune répétition entre M1, M2 et M3', () {
      final byOne = drawing({'no_pass', 'reversed', 'one_answer'});
      final byTwo = drawing({
        'no_pass',
        'reversed',
        'one_answer',
        'other_language',
        'sounds_only',
        'mime_under_sheet',
      }, count: 2);
      for (var i = 0; i < seeds; i++) {
        final one = [for (var r = 1; r <= 3; r++) ...round(byOne, 'g$i', r)];
        expect(one, hasLength(3));
        expect(one.toSet(), hasLength(3), reason: 'g$i');
        final two = [for (var r = 1; r <= 3; r++) ...round(byTwo, 'g$i', r)];
        expect(two, hasLength(6));
        expect(two.toSet(), hasLength(6), reason: 'g$i');
      }
    });

    test('vivier trop petit : les frais, puis un complément sans doublon', () {
      final rules = drawing({'no_pass', 'reversed', 'one_answer'}, count: 2);
      for (var i = 0; i < seeds; i++) {
        final m1 = round(rules, 'g$i', 1);
        final m2 = round(rules, 'g$i', 2);
        final m3 = round(rules, 'g$i', 3);
        for (final drawn in [m1, m2, m3]) {
          expect(drawn, hasLength(2));
          expect(drawn.toSet(), hasLength(2));
        }
        final fresh = {'no_pass', 'reversed', 'one_answer'}.difference(
          m1.toSet(),
        );
        expect(m2.toSet().containsAll(fresh), isTrue, reason: 'g$i');

        // Vivier rempli en M2 : seul le complément compte comme sorti.
        final refill = m2.toSet().intersection(m1.toSet());
        expect(m3.toSet().intersection(refill), isEmpty, reason: 'g$i');
      }
    });

    test('vivier épuisé pile à la fin d\'une manche : M3 repart du plein', () {
      final rules = drawing({'no_pass', 'reversed'});
      for (var i = 0; i < seeds; i++) {
        final m1 = round(rules, 'g$i', 1);
        final m2 = round(rules, 'g$i', 2);
        expect({...m1, ...m2}, {'no_pass', 'reversed'}, reason: 'g$i');
        expect(round(rules, 'g$i', 3), hasLength(1));
      }
    });

    test('un seul candidat : il ressort à chaque manche', () {
      final rules = drawing({'reversed'});
      for (var r = 1; r <= 3; r++) {
        expect(round(rules, 'g', r), ['reversed']);
      }
    });

    test('le mime n\'est pas consommé avant M3, la parole jamais en M3', () {
      final mime = drawing({'reversed', 'one_answer', 'mime_no_arms'});
      final speech = drawing({'reversed', 'other_language'});
      for (var i = 0; i < seeds; i++) {
        expect(round(mime, 'g$i', 1), isNot(contains('mime_no_arms')));
        expect(round(mime, 'g$i', 2), isNot(contains('mime_no_arms')));
        expect(round(mime, 'g$i', 3), ['mime_no_arms'], reason: 'g$i');

        expect({
          ...round(speech, 'g$i', 1),
          ...round(speech, 'g$i', 2)
        }, {
          'reversed',
          'other_language'
        }, reason: 'g$i');
        expect(round(speech, 'g$i', 3), ['reversed'], reason: 'g$i');
      }
    });

    test('frais incompatibles : complément avec un déjà sorti compatible', () {
      final rules = drawing(
          {'reversed', 'one_answer', 'mime_no_arms', 'mime_eyes_closed'},
          count: 2);
      for (var i = 0; i < seeds; i++) {
        final m3 = round(rules, 'g$i', 3);
        expect(m3, hasLength(2), reason: 'g$i');
        expect(m3.toSet(), hasLength(2));
        expect(m3.where((id) => id.startsWith('mime_')), hasLength(1),
            reason: 'un seul mime possible ; l\'autre vient des déjà sortis');
      }
    });

    test('Toujours : hors tirage, et ne le consomme pas', () {
      final rules = FiestaRules(drawCount: 1, modifiers: const {
        'one_answer': ModifierSetting(always: true, draw: true),
        'reversed': ModifierSetting(draw: true),
        'no_pass': ModifierSetting(draw: true),
        'mime_no_arms': ModifierSetting(always: true),
        'mime_eyes_closed': ModifierSetting(draw: true),
      });
      for (var i = 0; i < seeds; i++) {
        final m1 = round(rules, 'g$i', 1);
        final m2 = round(rules, 'g$i', 2);
        final m3 = round(rules, 'g$i', 3);
        expect(m1, hasLength(2));
        expect(m1, contains('one_answer'));
        expect(m2, contains('one_answer'));
        expect(m3, containsAll(['one_answer', 'mime_no_arms']));
        expect(m3, isNot(contains('mime_eyes_closed')));
        expect(m3, hasLength(3));
        expect(
            {...m1, ...m2}.difference({'one_answer'}), {'reversed', 'no_pass'},
            reason: 'g$i');
      }
    });

    test('M1 garde le tirage de sa seule graine', () {
      final rules = drawing({'no_pass', 'reversed', 'one_answer'});
      for (var i = 0; i < seeds; i++) {
        expect(
            round(rules, 'g$i', 1),
            drawForRound(
              rules: rules,
              round: 1,
              already: const [],
              random: Random(drawSeed('g$i', 1)),
            ).map((m) => m.catalogId));
      }
    });

    test('déterministe : M3 directement = M3 après M1 puis M2', () {
      final rules = drawing({'no_pass', 'reversed', 'one_answer'}, count: 2);
      for (var i = 0; i < seeds; i++) {
        final direct = round(rules, 'g$i', 3);
        round(rules, 'g$i', 1);
        round(rules, 'g$i', 2);
        expect(round(rules, 'g$i', 3), direct, reason: 'g$i');
      }
    });

    test('drawCount 0 : aucun tirage, les Toujours restent', () {
      final rules = FiestaRules(drawCount: 0, modifiers: const {
        'reversed': ModifierSetting(draw: true),
        'no_pass': ModifierSetting(always: true),
      });
      for (var r = 1; r <= 3; r++) {
        expect(round(rules, 'g', r), ['no_pass']);
      }
    });

    test('récap, transition et défi lisent le même tirage', () {
      final rules =
          FiestaRules(drawCount: 2, challenges: true, modifiers: const {
        'no_pass': ModifierSetting(draw: true),
        'reversed': ModifierSetting(draw: true),
        'one_answer': ModifierSetting(draw: true),
        'mime_no_arms': ModifierSetting(draw: true),
      });
      final fiesta = FiestaState(rules: rules);
      const scores = {'a': 9, 'b': 3, 'c': 5};
      var challenges = 0;
      for (var i = 0; i < seeds; i++) {
        final gameId = 'g$i';
        final recap =
            buildModifierRecap(rules: rules, gameId: gameId, roundsPlayed: 3);
        for (final finished in [1, 2]) {
          final draw = planRoundTransition(
            fiesta: fiesta,
            gameId: gameId,
            finishedRound: finished,
            scores: scores,
            totalWords: 40,
            blockableTeamIds: const {},
          )!
              .draw
              .map((m) => m.catalogId)
              .toList();
          expect(draw, round(rules, gameId, finished + 1));
          expect(
            [
              for (final item in recap)
                if (item.round == finished + 1) item.catalogId
            ],
            draw,
            reason: gameId,
          );

          final plan = planChallenge(
            fiesta: fiesta,
            gameId: gameId,
            finishedRound: finished,
            scores: scores,
            rosters: const {
              'a': ['a1'],
              'b': ['b1'],
              'c': ['c1'],
            },
            turns: const [],
            guessedWords: const ['mot'],
            blockableTeamIds: const {},
          );
          if (plan == null) continue;
          challenges++;
          expect(draw, isNot(contains(plan.first.prizeId)));
          expect(draw, isNot(contains(plan.second.prizeId)));
        }
      }
      expect(challenges, greaterThan(0));
    });
  });
}
