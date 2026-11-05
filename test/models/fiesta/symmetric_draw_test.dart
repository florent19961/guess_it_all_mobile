import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
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
}
