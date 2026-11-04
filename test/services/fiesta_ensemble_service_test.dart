import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_validation.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';

import '../helpers/test_prefs.dart';

const key = FiestaEnsembleService.storageKey;

/// Blob FIGÉ, tel qu'écrit par la version qui introduit les ensembles (2-3).
/// 🔴 Ne jamais le régénérer : s'il ne se relit plus en entier, c'est qu'un
/// changement de `FiestaRules` effacerait les ensembles des joueurs.
const frozenBlob = '{"schemaVersion":1,"data":{"ensembles":[{"id":"e1",'
    '"rules":{"mode":"custom","symmetric":true,"autoCalibrate":true,'
    '"ensembleName":"Soirée chez Max","modifiers":{"no_pass":{"active":true,'
    '"arrival":"draw","startRound":1,"fixedRound":3,"charges":0},'
    '"free_pass":{"active":false,"arrival":"offer","startRound":2,'
    '"fixedRound":3,"charges":2}},"oneOfThree":true,"catchUp":{"b1":3,'
    '"b2":5,"cap":30,"mal":1,"malCap":15},"drawCount":2,"oneAnswer":false,'
    '"carryOver":true}}],"lastUsedId":"e1"}}';

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

  test('format figé de la 1re version : relu en entier', () async {
    await givenPrefs({key: frozenBlob});

    final store = await service.load();
    expect(store.lastUsedId, 'e1');
    final rules = store.ensembles.single.rules;
    expect(rules.ensembleName, 'Soirée chez Max');
    expect(rules.modifiers.keys, ['no_pass', 'free_pass']);
    expect(rules.modifiers['free_pass']!.charges, 2);
    expect(rules.drawCount, 2);
    expect(rules.oneAnswer, isFalse);
    expect(rules.catchUp.b2, 5);
  });

  test(
      'ensemble d\'avant la famille « Mime » (deux mimes fixés sur M3) : '
      'relu sans planter, un seul mime gardé — celui que le jeu appliquait',
      () async {
    String mod(String arrival, {bool active = true}) =>
        '{"active":$active,"arrival":"$arrival","startRound":3,'
        '"fixedRound":3,"charges":0}';
    await givenPrefs({
      key: '{"schemaVersion":1,"data":{"ensembles":[{"id":"e1","rules":'
          '{"mode":"custom","ensembleName":"Vieux","modifiers":{'
          '"draw":${mod('fixed')},"mime_eyes_closed":${mod('fixed')},'
          '"mime_no_arms":${mod('draw')},"no_pass":${mod('draw')}}}}]}}',
    });

    final rules = (await service.load()).ensembles.single.rules;
    // Les fixés passaient avant le tirage, dans l'ordre du catalogue :
    // `mime_eyes_closed` d'abord, puis « Dessiner » et `mime_no_arms` (tiré)
    // étaient refusés comme incompatibles.
    expect(
      {for (final e in rules.modifiers.entries) e.key: e.value.active},
      {
        'draw': false,
        'mime_eyes_closed': true,
        'mime_no_arms': false,
        'no_pass': true,
      },
    );
    expect(rules.modifiers['draw']!.arrival, ModifierArrival.fixed,
        reason: 'réglages conservés, seul `active` change');
    expect(validateEnsemble(rules), isEmpty);
  });

  test(
      'écriture figée : une clé vide ou nulle est omise (blob Fiesta et '
      'ensembles), et l\'absence se relit comme le défaut', () async {
    final fiesta = FiestaState(rules: FiestaRules(mode: FiestaMode.auto));
    const frozenFiesta = '{"rules":{"mode":"auto","symmetric":true,'
        '"autoCalibrate":true,"modifiers":{},"oneOfThree":false,"catchUp":'
        '{"b1":3,"b2":5,"cap":30,"mal":1,"malCap":15},"drawCount":1,'
        '"oneAnswer":true}}';
    expect(jsonEncode(fiesta.toJson()), frozenFiesta);
    final relu = FiestaState.tryFromJson(jsonDecode(frozenFiesta))!;
    expect([relu.active, relu.turn, relu.catchUpDue, relu.rules.ensembleName],
        [isEmpty, isEmpty, isEmpty, isNull]);

    const forAll = ModifierInstance(
      catalogId: 'no_pass',
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: 2,
    );
    expect(
        jsonEncode(forAll.toJson()),
        '{"catalogId":"no_pass","scope":"round","target":"both","charges":0,'
        '"nature":"malus","round":2}');

    await givenPrefs();
    await service.create(FiestaRules(
      mode: FiestaMode.custom,
      ensembleName: 'E',
      modifiers: {
        'no_pass': const ModifierSetting(
            active: true,
            arrival: ModifierArrival.draw,
            startRound: 1,
            charges: 0),
      },
    ));
    final data = jsonDecode((await rawString(key))!)['data'] as Map;
    expect(data.containsKey('lastUsedId'), isFalse);
    expect(
        jsonEncode(data['ensembles'][0]['rules']['modifiers']),
        '{"no_pass":{"active":true,"arrival":"draw","startRound":1,'
        '"charges":0}}');
    expect(
        (await service.load())
            .ensembles
            .single
            .rules
            .modifiers['no_pass']!
            .fixedRound,
        isNull);
  });

  test('supprimer le dernier utilisé efface lastUsedId (AC6)', () async {
    await givenPrefs();
    final a = (await service.create(defaultEnsembleRules('A')))!;
    final b = (await service.create(defaultEnsembleRules('B')))!;
    await service.markUsed(a.id);

    await service.delete(a.id);

    final store = await service.load();
    expect(store.ensembles.map((e) => e.id), [b.id]);
    expect(store.lastUsedId, isNull, reason: 'sinon il pointe dans le vide');
  });

  test('la copie d\'un nom de 30 caractères reste distincte', () {
    final name = 'x' * FiestaEnsembleService.maxNameLength;
    final copy = FiestaEnsembleService.copyName(name);
    expect(copy, isNot(name));
    expect(copy, endsWith(' (copie)'));
    expect(copy.length, FiestaEnsembleService.maxNameLength);
  });

  group('lecture tolérante', () {
    test('blob illisible → quarantaine, liste vide, pas de crash', () async {
      await givenPrefs({key: '{pas du json'});

      expect((await service.load()).ensembles, isEmpty);
      expect(await rawString(key), isNull, reason: 'blob supprimé');
    });

    test('blob venu du futur → quarantaine', () async {
      await givenPrefs({
        key: jsonEncode(
            {'schemaVersion': kCurrentSchemaVersion + 1, 'data': {}}),
      });

      expect((await service.load()).ensembles, isEmpty);
      expect(await rawString(key), isNull);
    });

    test('ensemble illisible ignoré seul, modificateur inconnu ignoré seul',
        () async {
      final good =
          FiestaEnsemble(id: 'a', rules: defaultEnsembleRules('A')).toJson();
      (good['rules'] as Map)['modifiers']['from_the_future'] =
          (good['rules'] as Map)['modifiers']['no_pass'];
      await givenPrefs({
        key: jsonEncode(wrapWithSchema({
          'ensembles': [
            good,
            {'id': 'b', 'rules': 'cassé'},
            'x', // pas même un objet
            // Règles Auto : un ensemble est toujours Personnalisé.
            FiestaEnsemble(id: 'c', rules: FiestaRules(mode: FiestaMode.auto))
                .toJson(),
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

      // Modifier un AUTRE ensemble ne détruit pas celui qu'on ne sait pas lire.
      await service.create(defaultEnsembleRules('C'));
      final stored = (await persistedData(key))!['ensembles'] as List;
      expect(stored, anyElement(equals({'id': 'b', 'rules': 'cassé'})));
      expect(stored, contains('x'));
      expect(stored, anyElement(isA<Map>().having((m) => m['id'], 'id', 'c')));
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
