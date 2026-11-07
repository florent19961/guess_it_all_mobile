import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_validation.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';

FiestaRules named(
  Map<String, ModifierSetting> modifiers, {
  int drawCount = 0,
  int trailingCount = 0,
}) =>
    FiestaRules(
      ensembleName: 'Max',
      modifiers: modifiers,
      drawCount: drawCount,
      trailingCount: trailingCount,
    );

void main() {
  group('Validation', () {
    test('nom vide ou pris, sans compter casse ni espaces', () {
      const on = {'no_pass': ModifierSetting(always: true)};
      expect(validateEnsemble(FiestaRules(ensembleName: '  ', modifiers: on)),
          contains('Donne un nom à l\'ensemble.'));
      final other = FiestaEnsemble(
          id: 'x', rules: FiestaRules(ensembleName: ' max ', allCount: 1));
      expect(validateEnsemble(named(on), others: [other]),
          contains('Ce nom est déjà pris : choisis-en un autre.'));
    });

    test('au moins un réglage qui joue', () {
      expect(validateEnsemble(named(const {})),
          contains('Active au moins un modificateur.'));
      // Aléatoire sans tirage : ne joue pas.
      expect(
          validateEnsemble(
              named(const {'no_pass': ModifierSetting(draw: true)})),
          contains('Active au moins un modificateur.'));
      expect(validateEnsemble(named(const {}, trailingCount: 1)), isEmpty);
      expect(
          validateEnsemble(
              named(const {'no_pass': ModifierSetting(charges: 1)})),
          isEmpty);
    });

    test('drawCount > 0 sans candidat', () {
      expect(validateEnsemble(named(const {}, drawCount: 1)).single,
          startsWith('Combien par manche'));
      // Le seul candidat est verrouillé par son Toujours.
      expect(
          validateEnsemble(named(const {
            'no_pass': ModifierSetting(always: true, draw: true),
          }, drawCount: 1))
              .single,
          startsWith('Combien par manche'));
    });

    test('rien à tirer à une manche : avertissement, pas une erreur', () {
      final mimes =
          named(const {'draw': ModifierSetting(draw: true)}, drawCount: 1);
      expect(validateEnsemble(mimes), isEmpty);
      expect(roundsWithoutDraw(mimes), [1, 2]);
      expect(roundsWithoutDraw(named(const {})), isEmpty);
    });

    test('doublon : mêmes réglages qui jouent, le reste ne compte pas', () {
      final a = FiestaEnsemble(
          id: 'a',
          rules: FiestaRules(
              ensembleName: 'A',
              modifiers: const {'no_pass': ModifierSetting(always: true)}));
      expect(
          validateEnsemble(
              named(const {
                // `draw` et `charges` gardés sous Toujours : sans effet.
                'no_pass':
                    ModifierSetting(always: true, draw: true, charges: 3),
              }),
              others: [a]).single,
          'L\'ensemble A a déjà ces paramètres.');
      expect(settingsKey(FiestaRules(balance: true, trailingCount: 4)),
          settingsKey(FiestaRules(balance: true)));
    });
  });

  group('Verrouillage', () {
    test('Toujours verrouille les 2 autres menus, réglages gardés', () {
      final rules = FiestaRules(modifiers: const {
        'reversed': ModifierSetting(always: true, draw: true, charges: 2),
      });
      expect(rules.lockReason('reversed', EnsembleMenu.draw), isNotNull);
      expect(rules.lockReason('reversed', EnsembleMenu.cartridge), isNotNull);
      expect(rules.lockReason('reversed', EnsembleMenu.always), isNull);
      expect(rules.drawsFrom('reversed'), isFalse);
      expect(rules.chargesOf('reversed'), 0);
      expect(rules.settingOf('reversed').charges, 2);
      final off = rules.copyWith(modifiers: {
        'reversed': rules.settingOf('reversed').copyWith(always: false),
      });
      expect(off.drawsFrom('reversed'), isTrue);
      expect(off.chargesOf('reversed'), 2);
    });

    test('mime en Toujours : les autres mimes partout, sauf la paire', () {
      final rules = FiestaRules(modifiers: const {
        'mime_under_sheet': ModifierSetting(always: true),
      });
      for (final menu in EnsembleMenu.values) {
        expect(rules.lockReason('mime_no_arms', menu),
            'Mimer sous un drap est en Toujours');
        expect(rules.lockReason('sounds_only', menu), isNull);
      }
    });

    test(
        'Interdit de passer en Toujours : Passe gratuite en Cartouches '
        'seulement', () {
      final rules = FiestaRules(modifiers: const {
        'no_pass': ModifierSetting(always: true),
        'free_pass': ModifierSetting(charges: 3),
        'plus_10s': ModifierSetting(charges: 1),
      });
      expect(rules.chargesOf('free_pass'), 0);
      expect(rules.chargesOf('plus_10s'), 1);
    });
  });

  group('Ensembles fournis', () {
    FiestaRules of(String id) =>
        kProvidedEnsembles.firstWhere((e) => e.id == id).rules;

    test('8, ids provided_*, L\'injustice retirée, distincts et valides', () {
      expect(kProvidedEnsembles.map((e) => e.id), [
        'provided_classic',
        'provided_last',
        'provided_pro',
        'provided_straight',
        'provided_pictionary',
        'provided_bilingual',
        'provided_explosive',
        'provided_expert',
      ]);
      expect(kProvidedEnsembles.map((e) => settingsKey(e.rules)).toSet(),
          hasLength(8));
      for (final e in kProvidedEnsembles) {
        expect(validateEnsemble(e.rules), isEmpty, reason: e.name);
      }
    });

    test('Fiesta classique : 5 cartouches par manche et équilibrage, rien '
        'd\'autre', () {
      final rules = of('provided_classic');
      expect(rules.allCount, 5);
      expect(rules.balance, isTrue);
      expect(rules.drawCount, 0);
      expect(rules.modifiers, isEmpty);
    });

    test('les autres', () {
      expect(of('provided_last').trailingCount, 5);
      expect(of('provided_explosive').allCount, 10);
      expect(of('provided_explosive').modifiers.values.any((s) => s.always),
          isFalse);
      Set<String> always(String id) =>
          of(id).modifiers.keys.where(of(id).isAlways).toSet();
      expect(always('provided_pro'), {'no_pass', 'reversed', 'one_answer'});
      expect(always('provided_straight'), {'one_answer'});
      expect(always('provided_pictionary'), {'draw'});
      expect(always('provided_bilingual'), {'other_language'});
      expect(always('provided_expert'), {'sounds_only', 'mime_under_sheet'});
    });
  });
}
