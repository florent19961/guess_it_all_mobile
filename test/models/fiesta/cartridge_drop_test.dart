import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/cartridge_drop.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';

ModifierInstance rule(String id, int round) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: round,
    );

final often = FiestaRules(dropFrequency: DropFrequency.often);

List<String> pool({
  FiestaRules? rules,
  int round = 1,
  List<ModifierInstance> roundRules = const [],
  List<String> received = const [],
  List<String> armed = const [],
  List<String> guessers = const ['p2', 'p3'],
  int gap = 0,
}) =>
    dropPool(
      rules: rules ?? often,
      round: round,
      roundRules: roundRules,
      received: received,
      armed: armed,
      guesserIds: guessers,
      gap: gap,
    ).map((d) => d.id).toList();

CartridgeDrop? drop(
  int turn, {
  FiestaRules? rules,
  String gameId = 'g',
  String giver = 'p1',
  int skips = 0,
  bool continuation = false,
}) =>
    dropForTurn(
      rules: rules ?? often,
      gameId: gameId,
      turnIndex: turn,
      giverId: giver,
      skips: skips,
      round: 1,
      roundRules: const [],
      received: const [],
      armed: const [],
      guesserIds: const ['p2', 'p3'],
      gap: 0,
      continuation: continuation,
    );

const mimes = [
  'mime_no_arms',
  'mime_no_fists',
  'mime_eyes_closed',
  'draw',
  'mime_under_sheet',
  'mime_back_turned',
  'sounds_only',
];

void main() {
  test(
      'réglage persisté : clé `dropFrequency` omise à Jamais, index sinon, '
      'hors bornes ou mal typé = illisible', () {
    expect(FiestaRules().toJson(), isNot(contains('dropFrequency')));
    final json = FiestaRules(dropFrequency: DropFrequency.sometimes).toJson();
    expect(json['dropFrequency'], 2);
    expect(
        FiestaRules.tryFromJson(json)!.dropFrequency, DropFrequency.sometimes);
    expect(FiestaRules.tryFromJson({'format': 4})!.dropFrequency,
        DropFrequency.never);
    for (final bad in [-1, 4, '2']) {
      expect(
          FiestaRules.tryFromJson({'format': 4, 'dropFrequency': bad}), isNull,
          reason: '$bad');
    }
  });

  group('tirage d\'un tour', () {
    final turns = [for (var t = 0; t < 60; t++) t];

    test(
        'déterministe par (partie, tour, joueur, sauts) ; la partie, le joueur '
        'et un saut de plus changent le tirage', () {
      final first = [for (final t in turns) drop(t)?.catalogId];
      expect([for (final t in turns) drop(t)?.catalogId], first);
      expect(first.whereType<String>(), isNotEmpty);
      expect(first, contains(isNull));
      expect([for (final t in turns) drop(t, giver: 'p4')?.catalogId],
          isNot(first));
      expect(
          [for (final t in turns) drop(t, skips: 1)?.catalogId], isNot(first));
      expect([for (final t in turns) drop(t, gameId: 'h')?.catalogId],
          isNot(first));
    });

    test('Rarement ⊂ Parfois ⊂ Souvent, tour par tour (même graine)', () {
      expect([for (final f in DropFrequency.values) f.chance],
          [0, 1 / 6, 1 / 4, 1 / 2]);
      Set<int> dropped(DropFrequency f) => {
            for (var t = 0; t < 200; t++)
              if (drop(t, rules: FiestaRules(dropFrequency: f)) != null) t,
          };
      final rarely = dropped(DropFrequency.rarely);
      final sometimes = dropped(DropFrequency.sometimes);
      final often = dropped(DropFrequency.often);
      expect(rarely, isNotEmpty);
      expect(sometimes.containsAll(rarely), isTrue);
      expect(often.containsAll(sometimes), isTrue);
      expect(rarely.length, lessThan(sometimes.length));
      expect(sometimes.length, lessThan(often.length));
    });

    test('rien à Jamais ni sur un tour de continuation', () {
      expect(turns.map(drop).whereType<CartridgeDrop>(), isNotEmpty);
      expect(turns.map((t) => drop(t, continuation: true)).whereType<Object>(),
          isEmpty);
      expect(
          turns.map((t) => drop(t, rules: FiestaRules())).whereType<Object>(),
          isEmpty);
    });

    test('Bloquer un devineur tombé : le bloqué est un des devineurs', () {
      final blocks = [
        for (var t = 0; t < 400; t++)
          if (drop(t) case CartridgeDrop(catalogId: 'block_guesser') && final d)
            d.blockedPlayerId,
      ];
      expect(blocks, isNotEmpty);
      expect(blocks.toSet(), {'p2', 'p3'});
      expect([
        for (var t = 0; t < 400; t++)
          if (drop(t) case final d? when d.catalogId != 'block_guesser')
            d.blockedPlayerId,
      ], everyElement(isNull));
    });
  });

  group('vivier', () {
    test('Toujours « Dessiner » en M3 : aucun mime ne tombe', () {
      expect(pool(round: 3), containsAll(mimes));
      final rules = often
          .copyWith(modifiers: {'draw': const ModifierSetting(always: true)});
      final p = pool(rules: rules, round: 3, roundRules: [rule('draw', 3)]);
      expect(p.toSet().intersection(mimes.toSet()), isEmpty);
      expect(p, contains('reversed'));
    });

    test('malus reçu : ni identique ni incompatible ; bonus armé : identique',
        () {
      expect(pool(round: 3), containsAll(['reversed', 'draw', 'plus_10s']));
      final p = pool(
          round: 3,
          received: ['reversed', 'mime_no_arms'],
          armed: ['plus_10s']);
      expect(p, isNot(contains('reversed')));
      expect(p, isNot(contains('draw')));
      expect(p, isNot(contains('plus_10s')));
      expect(p, contains('one_answer'));
    });

    test('×2 seulement à plus de 10 points du leader', () {
      expect(pool(gap: 10), isNot(contains('double_points')));
      expect(pool(gap: 11), contains('double_points'));
    });

    test(
        'Bloquer un devineur : 3 joueurs au moins ; Interdit de faire deviner '
        'toujours', () {
      expect(pool(guessers: ['p2']), isNot(contains('block_guesser')));
      expect(pool(guessers: ['p2']), contains('block_giver'));
      expect(pool(guessers: ['p2', 'p3']), contains('block_guesser'));
    });
  });
}
