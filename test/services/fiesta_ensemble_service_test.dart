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

/// Blob FIGÉ, tel qu'écrit par la version Fiesta v3 (modes et cartouches pour
/// la partie).
/// 🔴 Ne jamais le régénérer : s'il ne se relit plus en entier, c'est qu'un
/// changement de `FiestaRules` effacerait les ensembles des joueurs.
const frozenBlob = '{"schemaVersion":1,"data":{"ensembles":[{"id":"e1",'
    '"rules":{"format":3,"mode":"custom",'
    '"ensembleName":"Soirée chez Max","modifiers":{"no_pass":{"active":true,'
    '"rounds":[1,2],"mode":"draw","charges":1},'
    '"free_pass":{"active":false,"rounds":[1,2,3],"mode":"cartridge",'
    '"charges":2}},"drawCount":2,"trailingBoost":true}}],"lastUsedId":"e1"}}';

/// Blob de la forme v2 (Fiesta v2, jamais publiée) : `stock`, `offer`,
/// `perGame`, `pick3Choices`, `catchUp`.
const v2Blob = '{"schemaVersion":1,"data":{"ensembles":[{"id":"old2",'
    '"rules":{"format":2,"mode":"custom","autoCalibrate":true,'
    '"ensembleName":"Soirée chez Max","modifiers":{"no_pass":{"active":true,'
    '"rounds":[1,2],"mode":"draw","charges":1,"perGame":false},'
    '"free_pass":{"active":false,"rounds":[2,3],"mode":"stock","charges":2,'
    '"perGame":true}},"drawCount":2,"pick3Choices":2,"catchUp":{"b1":0,'
    '"b2":0,"cap":0,"mal":0,"malCap":0}}}],"lastUsedId":"old2"}}';

/// Blob de la forme v1 (avant Fiesta v2, jamais publiée) : `arrival`,
/// `symmetric`, `oneOfThree`, `oneAnswer`.
const v1Blob = '{"schemaVersion":1,"data":{"ensembles":[{"id":"old",'
    '"rules":{"mode":"custom","symmetric":true,"autoCalibrate":true,'
    '"ensembleName":"Soirée chez Max","modifiers":{"no_pass":{"active":true,'
    '"arrival":"draw","startRound":1,"fixedRound":3,"charges":0}},'
    '"oneOfThree":true,"catchUp":{"b1":3,"b2":5,"cap":30,"mal":1,'
    '"malCap":15},"drawCount":2,"oneAnswer":false}}],"lastUsedId":"old"}}';

void main() {
  final service = FiestaEnsembleService();

  test('aller-retour : enveloppe versionnée, réglages et dernier utilisé',
      () async {
    await givenPrefs();
    final rules = defaultEnsembleRules('Soirée chez Max').copyWith(
      drawCount: 2,
      trailingBoost: false,
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

  test('format figé Fiesta v3 : relu en entier', () async {
    await givenPrefs({key: frozenBlob});

    final store = await service.load();
    expect(store.lastUsedId, 'e1');
    final rules = store.ensembles.single.rules;
    expect(rules.ensembleName, 'Soirée chez Max');
    expect(rules.modifiers.keys, ['no_pass', 'free_pass']);
    expect(rules.modifiers['no_pass']!.rounds, {1, 2});
    expect(rules.modifiers['free_pass']!.charges, 2);
    expect(rules.modifiers['free_pass']!.mode, ModifierMode.cartridge);
    expect([rules.drawCount, rules.trailingBoost], [2, true]);
  });

  test(
      'ensemble de la forme v2 (avant Fiesta v3) : ignoré sans planter, jamais '
      'détruit par une écriture', () async {
    await givenPrefs({key: v2Blob});

    expect((await service.load()).ensembles, isEmpty);
    await service.create(defaultEnsembleRules('Neuf'));
    expect((await service.load()).ensembles.map((e) => e.name), ['Neuf']);
    final stored = (await persistedData(key))!['ensembles'] as List;
    expect(stored, anyElement(isA<Map>().having((m) => m['id'], 'id', 'old2')));
  });

  test(
      'ensemble de la forme v1 (avant Fiesta v2) : ignoré sans planter, '
      'jamais détruit par une écriture', () async {
    await givenPrefs({key: v1Blob});

    expect((await service.load()).ensembles, isEmpty);
    await service.create(defaultEnsembleRules('Neuf'));
    expect((await service.load()).ensembles.map((e) => e.name), ['Neuf']);
    final stored = (await persistedData(key))!['ensembles'] as List;
    expect(stored, anyElement(isA<Map>().having((m) => m['id'], 'id', 'old')));
  });

  test(
      'ensemble à plusieurs mimes actifs (blob non écrit par l\'éditeur) : '
      'relu sans planter, un seul mime gardé : le 1er « Toujours » dans '
      'l\'ordre du catalogue', () async {
    String mod(String mode) => '{"active":true,"rounds":[3],"mode":"$mode"}';
    await givenPrefs({
      key: '{"schemaVersion":1,"data":{"ensembles":[{"id":"e1","rules":'
          '{"format":3,"mode":"custom","ensembleName":"Vieux","modifiers":{'
          '"draw":${mod('always')},"mime_eyes_closed":${mod('always')},'
          '"mime_no_arms":${mod('draw')},"no_pass":${mod('draw')}}}}]}}',
    });

    final rules = (await service.load()).ensembles.single.rules;
    // Les « Toujours » passent avant le tirage, dans l'ordre du catalogue :
    // `mime_eyes_closed` d'abord, puis « Dessiner » et `mime_no_arms` (tiré)
    // seraient refusés comme incompatibles.
    expect(
      {for (final e in rules.modifiers.entries) e.key: e.value.active},
      {
        'draw': false,
        'mime_eyes_closed': true,
        'mime_no_arms': false,
        'no_pass': true,
      },
    );
    expect(rules.modifiers['draw']!.mode, ModifierMode.always,
        reason: 'réglages conservés, seul `active` change');
    expect(validateEnsemble(rules), isEmpty);
  });

  test(
      'écriture figée : une clé vide ou nulle est omise (blob Fiesta et '
      'ensembles), et l\'absence se relit comme le défaut', () async {
    final fiesta = FiestaState(rules: FiestaRules(mode: FiestaMode.auto));
    const frozenFiesta = '{"rules":{"format":3,"mode":"auto",'
        '"modifiers":{},"drawCount":1,"trailingBoost":false}}';
    expect(jsonEncode(fiesta.toJson()), frozenFiesta);
    final relu = FiestaState.tryFromJson(jsonDecode(frozenFiesta))!;
    expect([relu.active, relu.turn, relu.earned, relu.rules.ensembleName],
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
    await service
        .create(FiestaRules(mode: FiestaMode.custom, ensembleName: 'E'));
    final data = jsonDecode((await rawString(key))!)['data'] as Map;
    expect(data.containsKey('lastUsedId'), isFalse);
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

  test(
      'copie : « Nom (2) », puis le premier numéro libre (casse ignorée) ; '
      'un nom de 30 caractères reste distinct et tient en 30', () {
    expect(FiestaEnsembleService.copyName('Pro Player', ['Pro Player']),
        'Pro Player (2)');
    expect(
        FiestaEnsembleService.copyName(
            'Pro Player', ['Pro Player', 'pro player (2)']),
        'Pro Player (3)');
    final name = 'x' * FiestaEnsembleService.maxNameLength;
    final copy = FiestaEnsembleService.copyName(name, [name]);
    expect(copy, isNot(name));
    expect(copy, endsWith(' (2)'));
    expect(copy.length, FiestaEnsembleService.maxNameLength);
  });

  test(
      'dupliquer un ensemble fourni : une copie à moi, en fin de liste, nom '
      'libre ; les fournis ne sont jamais écrits', () async {
    await givenPrefs();
    final mine = (await service.create(defaultEnsembleRules('A')))!;
    final copy = (await service.duplicate(classicEnsemble))!;
    expect(copy.isProvided, isFalse);
    expect(copy.name, 'Fiesta classique (2)');
    expect(
        (await service.load()).ensembles.map((e) => e.id), [mine.id, copy.id]);
    final stored = (await persistedData(key))!['ensembles'] as List;
    expect(stored.map((e) => (e as Map)['id']),
        isNot(contains(kClassicEnsembleId)));
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
      service.duplicate(first),
    ]);
    expect(racing.whereType<FiestaEnsemble>(), hasLength(1));

    expect(await service.create(defaultEnsembleRules('trop')), isNull);
    expect(await service.duplicate(first), isNull);
    expect((await service.load()).ensembles,
        hasLength(FiestaEnsembleService.maxEnsembles));
  });
}
