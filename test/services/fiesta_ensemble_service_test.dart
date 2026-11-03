import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';

import '../helpers/test_prefs.dart';

const key = FiestaEnsembleService.storageKey;

void main() {
  final service = FiestaEnsembleService();

  test('aller-retour : enveloppe versionnée, réglages et dernier utilisé',
      () async {
    await givenPrefs();
    final rules = defaultEnsembleRules('Soirée chez Max').copyWith(
      drawCount: 2,
      oneAnswer: false,
      catchUp: const CatchUpRules(b1: 1, b2: 2, cap: 10, mal: 0, malCap: 0),
    );

    final created = (await service.create(rules))!;
    await service.markUsed(created.id);

    final decoded = jsonDecode((await rawString(key))!);
    expect(decoded['schemaVersion'], kCurrentSchemaVersion,
        reason: 'versionnée dès la première écriture (règle 7)');

    final store = await service.load();
    expect(store.lastUsedId, created.id);
    final restored = store.ensembles.single;
    expect(restored.id, created.id);
    expect(jsonEncode(restored.rules.toJson()), jsonEncode(rules.toJson()));
  });

  group('lecture tolérante', () {
    test('blob illisible → quarantaine, liste vide, pas de crash', () async {
      await givenPrefs({key: '{pas du json'});

      expect((await service.load()).ensembles, isEmpty);
      expect(await rawString(key), isNull, reason: 'blob supprimé');
    });

    test('blob venu du futur → quarantaine', () async {
      await givenPrefs({
        key: jsonEncode({'schemaVersion': kCurrentSchemaVersion + 1, 'data': {}}),
      });

      expect((await service.load()).ensembles, isEmpty);
      expect(await rawString(key), isNull);
    });

    test('ensemble illisible ignoré seul, modificateur inconnu ignoré seul',
        () async {
      final good = FiestaEnsemble(id: 'a', rules: defaultEnsembleRules('A'))
          .toJson();
      (good['rules'] as Map)['modifiers']['from_the_future'] =
          (good['rules'] as Map)['modifiers']['no_pass'];
      await givenPrefs({
        key: jsonEncode(wrapWithSchema({
          'ensembles': [
            good,
            {'id': 'b', 'rules': 'cassé'},
          ],
          'lastUsedId': null,
        })),
      });

      final ensembles = (await service.load()).ensembles;
      expect(ensembles.map((e) => e.id), ['a']);
      expect(ensembles.single.rules.modifiers.containsKey('from_the_future'),
          isFalse);
      expect(ensembles.single.rules.modifiers.containsKey('no_pass'), isTrue);
      expect(await rawString(key), isNotNull, reason: 'pas de quarantaine');
    });
  });

  test('la borne de 10 est tenue par le service (créer et dupliquer)',
      () async {
    await givenPrefs();
    for (var i = 0; i < FiestaEnsembleService.maxEnsembles - 1; i++) {
      expect(await service.create(defaultEnsembleRules('E$i')), isNotNull);
    }
    final first = (await service.load()).ensembles.first;

    // Deux taps rapides à 9 : les écritures sont asynchrones, une seule passe.
    final racing = await Future.wait([
      service.create(defaultEnsembleRules('E9')),
      service.duplicate(first.id),
    ]);
    expect(racing.whereType<FiestaEnsemble>(), hasLength(1));

    expect(await service.create(defaultEnsembleRules('trop')), isNull);
    expect(await service.duplicate(first.id), isNull);
    expect((await service.load()).ensembles,
        hasLength(FiestaEnsembleService.maxEnsembles));
  });
}
