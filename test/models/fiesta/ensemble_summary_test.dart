import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_summary.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';

/// Une pastille lisible et comparable.
String chipText(EnsembleChip chip) => switch (chip) {
      ModifierChip(:final id, :final count) =>
        count == null ? id : '$id ×$count',
      InfoChip(:final label) => label,
    };

List<String> chips(FiestaRules rules) =>
    rulesSummary(rules).chips.map(chipText).toList();

void main() {
  group('Ensembles fournis', () {
    test('chacun a son texte écrit à la main', () {
      for (final ensemble in kProvidedEnsembles) {
        final summary = kProvidedSummaries[ensemble.id];
        expect(summary, isNotNull, reason: ensemble.name);
        expect(summary!.short, isNotEmpty, reason: ensemble.name);
        expect(summary.long, isNotEmpty, reason: ensemble.name);
        expect(summary.chips, isNotEmpty, reason: ensemble.name);
        expect(ensembleSummary(ensemble), same(summary));
      }
      expect(kProvidedSummaries, hasLength(kProvidedEnsembles.length));
    });

    test('leurs pastilles disent les mêmes règles que le moteur joue', () {
      for (final ensemble in kProvidedEnsembles) {
        expect(
          kProvidedSummaries[ensemble.id]!.chips.map(chipText).toSet(),
          chips(ensemble.rules).toSet(),
          reason: ensemble.name,
        );
      }
    });

    test('leur copie, un ensemble perso, passe au texte généré', () {
      final copy = FiestaEnsemble(id: 'copy', rules: classicEnsemble.rules);
      expect(
          ensembleSummary(copy).short, 'Équilibrage · 5 cartouches par manche');
    });
  });

  group('Ensembles perso, textes générés', () {
    test('exemple de la maquette', () {
      final summary = rulesSummary(FiestaRules(
        modifiers: {
          'one_answer': const ModifierSetting(always: true),
          'reversed': const ModifierSetting(draw: true),
          'double_points': const ModifierSetting(charges: 1),
        },
        drawCount: 2,
      ));
      expect(summary.short, '1 règle fixe · 2 tirées par manche · 1 cartouche');
      expect(
        summary.long,
        'Toujours : Une seule réponse. 2 règles tirées à chaque manche. '
        'Mot compte double : ×1 pour chaque équipe.',
      );
      expect(summary.chips.map(chipText), [
        'one_answer',
        '2 tirages par manche',
        'double_points ×1',
      ]);
    });

    test('singulier et pluriel', () {
      final one = rulesSummary(FiestaRules(
        modifiers: {
          'reversed': const ModifierSetting(always: true),
          'one_answer': const ModifierSetting(draw: true),
          'double_points': const ModifierSetting(charges: 1),
        },
        drawCount: 1,
        trailingCount: 1,
      ));
      expect(
          one.short,
          '1 règle fixe · 1 tirée par manche · 1 cartouche · '
          'et plus');
      expect(one.long, contains('1 règle tirée à chaque manche.'));
      expect(one.long, contains('Aux équipes menées : 1 cartouche après'));
      expect(one.chips.map(chipText), contains('1 tirage par manche'));

      final many = rulesSummary(FiestaRules(
        modifiers: {
          'reversed': const ModifierSetting(always: true),
          'no_pass': const ModifierSetting(always: true),
          'one_answer': const ModifierSetting(draw: true),
          'double_points': const ModifierSetting(charges: 2),
        },
        drawCount: 2,
        allCount: 3,
      ));
      expect(many.short, startsWith('2 règles fixes · 2 tirées par manche'));
      expect(many.long, startsWith('Toujours : Interdit de passer, Mot à'));
      expect(many.long, contains('2 règles tirées à chaque manche.'));
      expect(many.long, contains('À tous, à chaque manche : 3 cartouches.'));
      expect(many.chips.map(chipText), contains('2 tirages par manche'));
    });

    test('« balance » remplace « trailingCount »', () {
      final balanced = FiestaRules(balance: true, trailingCount: 3);
      final summary = rulesSummary(balanced);
      expect(summary.short, 'Équilibrage');
      expect(summary.long, contains('Équilibrer la partie'));
      expect(summary.long, isNot(contains('Aux équipes menées')));
      expect(chips(balanced), ['Équilibrer la partie']);

      final trailing = FiestaRules(trailingCount: 3);
      expect(rulesSummary(trailing).short, '3 cartouches aux menées');
      expect(chips(trailing), ['Aux équipes menées : 3 cartouches']);
    });

    test('un pool sans tirage ne compte pas, ni un tirage sans pool', () {
      final poolOnly = FiestaRules(
        modifiers: {'reversed': const ModifierSetting(draw: true)},
        trailingCount: 1,
      );
      expect(rulesSummary(poolOnly).short, isNot(contains('tirée')));
      expect(rulesSummary(poolOnly).long, isNot(contains('tirée')));
      expect(chips(poolOnly), ['Aux équipes menées : 1 cartouche']);
      expect(rulesDraw(poolOnly), isFalse);

      final drawOnly = FiestaRules(
        drawCount: 2,
        modifiers: {'one_answer': const ModifierSetting(always: true)},
      );
      expect(rulesSummary(drawOnly).short, '1 règle fixe');
      expect(chips(drawOnly), ['one_answer']);
      expect(rulesDraw(drawOnly), isFalse);
    });

    test('ce qui est verrouillé ne joue pas, donc n\'est pas dit', () {
      final locked = FiestaRules(modifiers: {
        'no_pass': const ModifierSetting(always: true),
        'free_pass': const ModifierSetting(charges: 2),
        // Fixe : ses cartouches et son tirage sont verrouillés.
        'reversed': const ModifierSetting(always: true, draw: true, charges: 2),
      }, drawCount: 1);
      expect(rulesSummary(locked).short, '2 règles fixes');
      expect(chips(locked), ['no_pass', 'reversed']);
      expect(rulesHaveCartridges(locked), isFalse);
    });

    test('défis surprises, et ensemble sans aucune règle : pas de crash', () {
      final challenges = FiestaRules(challenges: true);
      expect(rulesSummary(challenges).short, 'Défis surprises');
      expect(rulesSummary(challenges).long, contains('une cartouche à gagner'));
      expect(chips(challenges), ['Défis surprises']);

      final empty = rulesSummary(FiestaRules());
      expect(empty.short, 'Aucune règle active');
      expect(empty.long, 'Cet ensemble n\'a aucune règle active.');
      expect(empty.chips, isEmpty);
    });

    test('les cartouches se comptent toutes, modificateur par modificateur',
        () {
      final rules = FiestaRules(modifiers: {
        'double_points': const ModifierSetting(charges: 2),
        'plus_10s': const ModifierSetting(charges: 3),
      });
      expect(rulesSummary(rules).short, '5 cartouches');
      expect(chips(rules), ['double_points ×2', 'plus_10s ×3']);
    });
  });
}
