import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';

ModifierInstance _instance(String id,
        {ModifierTarget target = ModifierTarget.both, String? teamId}) =>
    ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: target,
      teamId: teamId,
      charges: 0,
      nature: ModifierNature.malus,
      round: 1,
    );

void main() {
  group('Catalogue Fiesta', () {
    test(
        '17 ids uniques, et la table d\'incompatibilités ne cite que des ids '
        'du catalogue', () {
      // 🔴 Ids FIGÉS : ils sont persistés dans les parties en cours et les
      // ensembles enregistrés. En renommer un rend ces données illisibles.
      final ids = kModifierCatalog.map((d) => d.id).toList();
      expect(ids, [
        'mime_no_arms',
        'mime_no_fists',
        'mime_eyes_closed',
        'draw',
        'no_pass',
        'free_pass',
        'minus_10s',
        'double_points',
        'reversed',
        'block_guesser',
        'mime_under_sheet',
        'mime_back_turned',
        'other_language',
        'one_answer',
        'sounds_only',
        'plus_10s',
        'block_giver',
      ]);

      for (final (a, b) in kModifierIncompatibilities) {
        expect(modifierById(a), isNotNull, reason: '$a hors catalogue');
        expect(modifierById(b), isNotNull, reason: '$b hors catalogue');
        expect(a, isNot(b));
      }
    });

    test('areCompatible est symétrique sur toutes les paires', () {
      final ids = kModifierCatalog.map((d) => d.id).toList();
      for (final a in ids) {
        for (final b in ids) {
          expect(areCompatible(a, b), areCompatible(b, a), reason: '$a / $b');
        }
      }
      expect(areCompatible('no_pass', 'free_pass'), isFalse);
      expect(areCompatible('free_pass', 'no_pass'), isFalse);
      // Famille « Mime » (« Dessiner » compris) : deux membres s'excluent
      // toujours ; hors famille, les mimes ne gênent personne.
      final family = kModifierCatalog.where((d) => d.mimeFamily).toList();
      expect(family.map((d) => d.id), {
        'mime_no_arms',
        'mime_no_fists',
        'mime_eyes_closed',
        'draw',
        'mime_under_sheet',
        'mime_back_turned',
        'sounds_only',
      });
      for (final a in family) {
        for (final b in family) {
          final pair =
              {a.id, b.id}.containsAll(['sounds_only', 'mime_under_sheet']);
          expect(areCompatible(a.id, b.id), pair, reason: '${a.id}/${b.id}');
        }
        expect(areCompatible(a.id, 'reversed'), isTrue, reason: a.id);
      }
      // « Autre langue » : compatible avec tout (jamais en M3, donc jamais
      // avec un mime).
      for (final id in ids) {
        expect(areCompatible('other_language', id), isTrue, reason: id);
      }
      expect(areCompatible('no_pass', 'reversed'), isTrue);
    });
  });

  group('canAdd', () {
    test('pas de plafond (Fiesta v2) : seules les incompatibilités limitent',
        () {
      final active = [
        _instance('reversed'),
        _instance('minus_10s'),
        _instance('one_answer'),
      ];
      expect(canAdd(active, _instance('no_pass')), isTrue);
      expect(
          canAdd(
              [_instance('reversed', target: ModifierTarget.team, teamId: 'A')],
              _instance('free_pass', target: ModifierTarget.team, teamId: 'B')),
          isTrue);
    });

    test(
        'une instance pour tous compte pour chaque équipe, compatibilité '
        'comprise', () {
      final active = [_instance('no_pass')];
      expect(
          canAdd(active,
              _instance('free_pass', target: ModifierTarget.team, teamId: 'B')),
          isFalse);
      expect(
          canAdd(active,
              _instance('reversed', target: ModifierTarget.team, teamId: 'B')),
          isTrue);
    });

    test('refuse une instance incompatible avec une instance active', () {
      expect(canAdd([_instance('no_pass')], _instance('free_pass')), isFalse);
      expect(canAdd([_instance('free_pass')], _instance('no_pass')), isFalse);
      expect(canAdd([_instance('no_pass')], _instance('reversed')), isTrue);
    });
  });
}
