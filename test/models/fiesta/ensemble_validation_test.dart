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
    // Une manche de moins : plus un doublon.
    final different = twin.copyWith(modifiers: {
      ...twin.modifiers,
      'reversed': setting(ModifierMode.draw, rounds: {2, 3}),
    });
    expect(validateEnsemble(different, others: kProvidedEnsembles), isEmpty);
    // Une cartouche de plus : un autre ensemble ; ses manches, elles, ne
    // comptent pas (une cartouche vaut pour toute la partie).
    final base = rulesWith();
    final minus = base.modifiers['minus_10s']!;
    FiestaRules withMinus(ModifierSetting s) =>
        base.copyWith(modifiers: {...base.modifiers, 'minus_10s': s});
    expect(settingsKey(withMinus(minus.copyWith(charges: 2))),
        isNot(settingsKey(base)));
    expect(
        settingsKey(withMinus(minus.copyWith(rounds: {2}))), settingsKey(base));
    // Le coup de pouce compte aussi.
    expect(settingsKey(base.copyWith(boostCount: 0)), isNot(settingsKey(base)));
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
      'exclusivité des modes : un bonus, le −10 s ou le blocage en règle de '
      'manche, « Une seule réponse » en cartouche, des manches interdites par '
      'le catalogue → refusés', () {
    expect(
      validateEnsemble(rulesWith(overrides: {
        'double_points': setting(ModifierMode.always),
        'plus_10s': setting(ModifierMode.draw),
        'minus_10s': setting(ModifierMode.draw),
        'block_guesser': setting(ModifierMode.draw),
      })),
      unorderedEquals([
        'Mot compte double : seulement en cartouche.',
        'Bonus de 10 s : seulement en cartouche.',
        'Malus de 10 s : seulement en cartouche.',
        'Bloquer un devineur : seulement en cartouche.',
      ]),
    );
    expect(
      validateEnsemble(rulesWith(overrides: {
        'one_answer': setting(ModifierMode.cartridge),
      })),
      ['Une seule réponse : jamais en cartouche.'],
    );
    expect(
      validateEnsemble(rulesWith(overrides: {
        'mime_no_arms': setting(ModifierMode.draw, rounds: {2, 3}),
        'other_language': setting(ModifierMode.draw, rounds: {2, 3}),
      })),
      unorderedEquals([
        'Mime sans les bras n\'existe qu\'en manche 3 (mime).',
        'Faire deviner dans une autre langue n\'existe pas en manche 3 '
            '(mime) : manche 1 ou 2 seulement.',
      ]),
    );
  });

  test(
      'cartouche à 0 : acceptée avec le coup de pouce, refusée sans ; coup de '
      'pouce sans aucun modificateur en Cartouche → refusé ; les manches d\'une '
      'cartouche ne sont pas jugées', () {
    final zero = ModifierSetting(
        active: true,
        rounds: const {},
        mode: ModifierMode.cartridge,
        charges: 0);
    final withZero = rulesWith(overrides: {'plus_10s': zero});
    expect(validateEnsemble(withZero), isEmpty);
    expect(validateEnsemble(withZero.copyWith(boostCount: 0)), [
      'Bonus de 10 s : 0 cartouche sans coup de pouce, elle ne servirait '
          'jamais. Mets-en au moins 1, ou allume le coup de pouce.'
    ]);
    expect(
      validateEnsemble(FiestaRules(
        mode: FiestaMode.custom,
        ensembleName: 'Sans cartouche',
        boostCount: 1,
        modifiers: {'one_answer': setting(ModifierMode.always)},
      )),
      ['Le coup de pouce a besoin d\'au moins un modificateur en Cartouche.'],
    );
  });

  group('mimes', () {
    ModifierSetting mime(ModifierMode mode) =>
        setting(mode, rounds: {3}).copyWith(charges: 1);

    test('plusieurs en Au tirage et Cartouche, sans Toujours : permis', () {
      expect(
        validateEnsemble(rulesWith(overrides: {
          'mime_no_arms': mime(ModifierMode.cartridge),
          'mime_no_fists': mime(ModifierMode.cartridge),
          'draw': mime(ModifierMode.draw),
          'mime_under_sheet': mime(ModifierMode.draw),
        })),
        isEmpty,
      );
    });

    test('un Toujours + un autre mime actif, quel que soit son mode : refusé',
        () {
      for (final other in ModifierMode.values) {
        expect(
          validateEnsemble(rulesWith(overrides: {
            'mime_no_arms':
                mime(ModifierMode.cartridge).copyWith(active: false),
            'draw': mime(ModifierMode.always),
            'mime_no_fists': mime(other),
          })),
          other == ModifierMode.always
              ? [
                  'Mime sans les poings est « Toujours » : retire Dessiner ou '
                      'change son mode.'
                ]
              : [
                  'Dessiner est « Toujours » : retire Mime sans les poings ou '
                      'change son mode.'
                ],
          reason: other.name,
        );
      }
    });

    test('un mime coupé ne gêne pas un Toujours', () {
      expect(
        validateEnsemble(rulesWith(overrides: {
          'mime_no_arms': mime(ModifierMode.cartridge).copyWith(active: false),
          'draw': mime(ModifierMode.always),
        })),
        isEmpty,
      );
    });
  });
}
