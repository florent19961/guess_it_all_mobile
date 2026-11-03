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
        '11 ids uniques, et la table d\'incompatibilités ne cite que des ids '
        'du catalogue', () {
      final ids = kModifierCatalog.map((d) => d.id).toList();
      expect(ids, hasLength(11));
      expect(ids.toSet(), hasLength(11));

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
      expect(areCompatible('no_pass', 'two_words'), isFalse);
      expect(areCompatible('two_words', 'no_pass'), isFalse);
      expect(areCompatible('mime_no_fists', 'draw'), isFalse);
      expect(areCompatible('no_pass', 'reversed'), isTrue);
    });
  });

  group('canAdd', () {
    test('refuse une 3ᵉ instance pour une même équipe et un même tour', () {
      final active = [_instance('reversed'), _instance('minus_10s')];
      expect(canAdd(active, _instance('no_pass')), isFalse);
      expect(canAdd(active, _instance('no_pass'), maxPerTurn: 3), isTrue);
    });

    test('ne compte que les instances qui pèsent sur la même équipe', () {
      final active = [
        _instance('reversed', target: ModifierTarget.team, teamId: 'A'),
        _instance('minus_10s', target: ModifierTarget.team, teamId: 'A'),
      ];
      expect(
          canAdd(active,
              _instance('no_pass', target: ModifierTarget.team, teamId: 'B')),
          isTrue);
      // Une instance « pour tous » pèse sur A, qui est déjà pleine.
      expect(canAdd(active, _instance('no_pass')), isFalse);
    });

    test('refuse une instance incompatible avec une instance active', () {
      expect(canAdd([_instance('no_pass')], _instance('two_words')), isFalse);
      expect(canAdd([_instance('two_words')], _instance('no_pass')), isFalse);
      expect(canAdd([_instance('no_pass')], _instance('reversed')), isTrue);
    });
  });
}
