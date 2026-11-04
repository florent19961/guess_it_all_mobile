import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_validation.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';

/// Ensemble par défaut (maquette `defaults()`) où l'on remplace des réglages.
FiestaRules rulesWith({
  String name = 'Soirée',
  Map<String, ModifierSetting> overrides = const {},
}) {
  final base = defaultEnsembleRules(name);
  return base.copyWith(modifiers: {...base.modifiers, ...overrides});
}

ModifierSetting setting(ModifierMode mode,
        {Set<int> rounds = const {1, 2, 3}}) =>
    ModifierSetting(active: true, rounds: rounds, mode: mode);

void main() {
  test(
      'cas nominaux : l\'ensemble par défaut et les 7 ensembles fournis sont '
      'valides, et deux à deux distincts (noms et réglages)', () {
    // Sans ce cas, une garde qui refuse TOUT passerait les tests ci-dessous.
    expect([
      for (final e in kProvidedEnsembles) (e.id, e.name)
    ], [
      ('provided_classic', 'Fiesta classique'),
      ('provided_pro', 'Pro Player'),
      ('provided_straight', 'Droit au but'),
      ('provided_explosive', 'Explosif'),
      ('provided_pictionary', 'Pictionnary'),
      ('provided_bilingual', 'Bilingue'),
      ('provided_injustice', 'L\'injustice'),
    ]);
    expect(validateEnsemble(rulesWith(), others: kProvidedEnsembles), isEmpty);
    for (final e in kProvidedEnsembles) {
      expect(
        validateEnsemble(e.rules,
            others: kProvidedEnsembles.where((o) => o.id != e.id)),
        isEmpty,
        reason: e.name,
      );
    }
  });

  test('nom vide après trim, ou déjà pris (casse et espaces ignorés)', () {
    expect(validateEnsemble(rulesWith(name: '   ')),
        ['Donne un nom à l\'ensemble.']);
    expect(
      validateEnsemble(rulesWith(name: '  pro PLAYER '),
          others: kProvidedEnsembles),
      ['Ce nom est déjà pris : choisis-en un autre.'],
    );
  });

  test('doublon : mêmes réglages qu\'un autre ensemble, hors nom → refusé', () {
    final pro = kProvidedEnsembles.firstWhere((e) => e.name == 'Pro Player');
    final twin = pro.rules.copyWith(
      ensembleName: 'Soirée chez Max',
      // Réglage d'un modificateur COUPÉ : ne change pas le jeu, donc doublon.
      modifiers: {
        ...pro.rules.modifiers,
        'two_words': pro.rules.modifiers['two_words']!.copyWith(charges: 3),
      },
    );
    expect(validateEnsemble(twin, others: kProvidedEnsembles),
        ['L\'ensemble Pro Player a déjà ces paramètres.']);
    // Une manche de plus : plus un doublon.
    final different = twin.copyWith(modifiers: {
      ...twin.modifiers,
      'reversed': setting(ModifierMode.draw, rounds: {2, 3}),
    });
    expect(validateEnsemble(different, others: kProvidedEnsembles), isEmpty);
  });

  test('modificateur actif sans manche → refusé, coupé → ignoré', () {
    expect(
      validateEnsemble(rulesWith(
          overrides: {'reversed': setting(ModifierMode.draw, rounds: {})})),
      ['Mot à l\'envers : coche au moins une manche.'],
    );
    expect(
      validateEnsemble(rulesWith(overrides: {
        'reversed': setting(ModifierMode.draw, rounds: {}).copyWith(
          active: false,
        ),
      })),
      isEmpty,
    );
  });

  test(
      'exclusivité des modes : une exception cartouche en règle de manche, '
      'des manches interdites par le catalogue, une offre en M1 seule → '
      'refusés', () {
    expect(
      validateEnsemble(rulesWith(overrides: {
        'double_points': setting(ModifierMode.always),
        'block_guesser': setting(ModifierMode.draw),
      })),
      [
        'Mot compte double : seulement en cartouche.',
        'Bloquer un devineur : seulement en cartouche.',
      ],
    );
    expect(
      validateEnsemble(rulesWith(overrides: {
        'mime_no_arms': setting(ModifierMode.draw, rounds: {2, 3}),
        'other_language': setting(ModifierMode.draw, rounds: {2, 3}),
        'two_words': setting(ModifierMode.offer, rounds: {1}),
      })),
      unorderedEquals([
        'Mime sans les bras n\'existe qu\'en manche 3 (mime).',
        'Faire deviner dans une autre langue n\'existe pas en manche 3 '
            '(mime) : manche 1 ou 2 seulement.',
        'Deux mots à la fois : en « 1 parmi 3 », la carte se gagne entre '
            'deux manches. Coche la manche 2 ou 3.',
      ]),
    );
  });

  test('deux « Toujours » incompatibles sur une même manche → refusé', () {
    expect(
      validateEnsemble(rulesWith(overrides: {
        'no_pass': setting(ModifierMode.always, rounds: {2}),
        'two_words': setting(ModifierMode.always, rounds: {1, 2}),
      })),
      [
        'Interdit de passer et Deux mots à la fois sont incompatibles : pas '
            '« Toujours » tous les deux en manche 2.'
      ],
    );
  });
}
