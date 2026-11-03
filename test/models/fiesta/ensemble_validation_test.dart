import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_validation.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';

/// Ensemble par défaut (maquette `mkSet`) où l'on remplace des réglages.
FiestaRules rulesWith({
  String name = 'Soirée',
  Map<String, ModifierSetting> overrides = const {},
  bool? oneOfThree,
  bool? symmetric,
  int? drawCount,
}) {
  final base = defaultEnsembleRules(name);
  return base.copyWith(
    modifiers: {...base.modifiers, ...overrides},
    oneOfThree: oneOfThree,
    symmetric: symmetric,
    drawCount: drawCount,
  );
}

ModifierSetting setting(
  ModifierArrival arrival, {
  int startRound = 1,
  int? fixedRound,
  bool active = true,
}) =>
    ModifierSetting(
      active: active,
      arrival: arrival,
      startRound: startRound,
      fixedRound: fixedRound,
      charges: 0,
    );

void main() {
  test('l\'ensemble par défaut est valide (cas nominal)', () {
    // Sans ce cas, une garde qui refuse TOUT passerait les tests ci-dessous.
    expect(validateEnsemble(rulesWith()), isEmpty);
  });

  test('nom vide après trim → refusé', () {
    expect(validateEnsemble(rulesWith(name: '   ')), hasLength(1));
  });

  group('« tiré pour tous » sans tirage', () {
    final drawn = {'no_pass': setting(ModifierArrival.draw)};

    test('tirage coupé → refusé', () {
      expect(
        validateEnsemble(rulesWith(overrides: drawn, symmetric: false)),
        contains(startsWith('Interdit de passer est tiré pour tous')),
      );
    });

    test('tirage à 0 → refusé', () {
      expect(
        validateEnsemble(rulesWith(overrides: drawn, drawCount: 0)),
        contains(startsWith('Interdit de passer est tiré pour tous')),
      );
    });

    test('modificateur désactivé → ignoré', () {
      // Le défaut a d'autres modificateurs tirés : on les coupe tous.
      final off = {
        for (final e in defaultEnsembleRules('x').modifiers.entries)
          if (e.value.arrival == ModifierArrival.draw)
            e.key: setting(ModifierArrival.draw, active: false),
      };
      expect(
        validateEnsemble(rulesWith(overrides: off, drawCount: 0)),
        isEmpty,
      );
    });
  });

  test('« proposé » avec le 1 parmi 3 coupé → refusé', () {
    // Le défaut propose déjà les bonus : un message par modificateur proposé.
    expect(validateEnsemble(rulesWith(oneOfThree: false)), isNotEmpty);
  });

  test('« proposé » dès la manche 1 → refusé', () {
    expect(
      validateEnsemble(rulesWith(overrides: {
        'free_pass': setting(ModifierArrival.offer, startRound: 1),
      })),
      hasLength(1),
    );
  });

  test('« fixé » sans manche → refusé', () {
    // Impossible par l'éditeur, possible dans un blob relu.
    expect(
      validateEnsemble(rulesWith(overrides: {
        'no_pass': setting(ModifierArrival.fixed),
      })),
      hasLength(1),
    );
  });

  group('manche 3 seulement', () {
    test('fixé sur une autre manche → refusé', () {
      expect(
        validateEnsemble(rulesWith(overrides: {
          'draw': setting(ModifierArrival.fixed, fixedRound: 2),
        })),
        hasLength(1),
      );
    });

    test('tiré dès la manche 2 → refusé', () {
      expect(
        validateEnsemble(rulesWith(overrides: {
          'mime_no_fists': setting(ModifierArrival.draw, startRound: 2),
        })),
        hasLength(1),
      );
    });
  });

  test('deux incompatibles fixés sur la même manche → refusé', () {
    final fixed = rulesWith(overrides: {
      'no_pass': setting(ModifierArrival.fixed, fixedRound: 2),
      'two_words': setting(ModifierArrival.fixed, fixedRound: 2),
    });
    expect(validateEnsemble(fixed), hasLength(1));

    final apart = rulesWith(overrides: {
      'no_pass': setting(ModifierArrival.fixed, fixedRound: 1),
      'two_words': setting(ModifierArrival.fixed, fixedRound: 2),
    });
    expect(validateEnsemble(apart), isEmpty,
        reason: 'sur deux manches différentes, ils ne se croisent pas');
  });
}
