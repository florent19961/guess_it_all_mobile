import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/round_transition.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';
import 'package:guess_it_all_mobile/models/fiesta/trailing_boost.dart';

ModifierSetting cartridge([int charges = 0]) => ModifierSetting(
    active: true,
    rounds: const {1, 2, 3},
    mode: ModifierMode.cartridge,
    charges: charges);

FiestaRules boosted(List<String> ids) => FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 0,
      boostCount: 1,
      modifiers: {for (final id in ids) id: cartridge()},
    );

const allBlockable = {'a', 'b', 'c'};

List<EarnedCartridge> gifts(
  FiestaRules rules,
  Map<String, int> scores, {
  String gameId = 'game-0',
  int finishedRound = 1,
  List<ModifierInstance> roundRules = const [],
  Set<String> blockable = allBlockable,
}) =>
    trailingBoostGifts(
      rules: rules,
      gameId: gameId,
      finishedRound: finishedRound,
      standings: Standings(scores),
      roundRules: roundRules,
      blockableTeamIds: blockable,
    );

ModifierInstance rule(String id, int round) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: modifierById(id)!.nature,
      round: round,
    );

void main() {
  final gameIds = List.generate(100, (i) => 'game-$i');
  final allCartridges = boosted([
    for (final def in kModifierCatalog)
      if (canBeCartridge(def)) def.id,
  ]);

  group('qui reçoit', () {
    test('chaque équipe NON en tête reçoit exactement UNE cartouche', () {
      final out = gifts(allCartridges, {'a': 9, 'b': 4, 'c': 1});
      expect(out.map((e) => e.teamId), ['c', 'b']);
      expect(out.every((e) => e.round == 2), isTrue);
    });

    test('égalité générale : personne', () {
      expect(gifts(allCartridges, {'a': 3, 'b': 3, 'c': 3}), isEmpty);
      expect(gifts(allCartridges, {'a': 0, 'b': 0}), isEmpty);
    });

    test('co-leaders : ils ne reçoivent rien, les autres si', () {
      expect(
          gifts(allCartridges, {'a': 5, 'b': 5, 'c': 2}).map((e) => e.teamId),
          ['c']);
    });

    test(
        'n cartouches distinctes par équipe menée, mêmes au rejeu ; moins si '
        'le vivier est plus petit', () {
      final three = allCartridges.copyWith(boostCount: 3);
      for (final gameId in gameIds) {
        final out = gifts(three, {'a': 9, 'b': 4, 'c': 1}, gameId: gameId);
        for (final team in ['b', 'c']) {
          final ids =
              out.where((e) => e.teamId == team).map((e) => e.catalogId);
          expect(ids.toSet(), hasLength(3), reason: gameId);
        }
        expect(
            gifts(three, {'a': 9, 'b': 4, 'c': 1}, gameId: gameId)
                .map((e) => e.catalogId),
            out.map((e) => e.catalogId));
      }
      final small = boosted(['plus_10s', 'free_pass']).copyWith(boostCount: 3);
      expect(gifts(small, {'a': 2, 'b': 0}).map((e) => e.catalogId).toSet(),
          {'plus_10s', 'free_pass'});
    });

    test('compteur à 0 : rien', () {
      expect(gifts(allCartridges.copyWith(boostCount: 0), {'a': 5, 'b': 0}),
          isEmpty);
    });
  });

  group('tirage déterministe par (gameId, manche, équipe)', () {
    test('figé : une mise à jour qui changerait le tirage se voit', () {
      expect(boostSeed('game-0', 1, 'b'), 1618404491);
      expect(
          gifts(allCartridges, {'a': 5, 'b': 0}).single.catalogId, 'no_pass');
    });

    test('même partie = même cadeau ; il ne dépend pas des autres équipes', () {
      for (final gameId in gameIds) {
        final alone =
            gifts(allCartridges, {'a': 9, 'b': 1}, gameId: gameId).single;
        final withC =
            gifts(allCartridges, {'a': 9, 'b': 1, 'c': 4}, gameId: gameId)
                .firstWhere((e) => e.teamId == 'b');
        expect(withC.catalogId, alone.catalogId);
      }
    });

    test('le hasard varie, et il couvre tout le vivier', () {
      final seen = {
        for (final gameId in gameIds)
          gifts(boosted(['plus_10s', 'free_pass', 'reversed']),
                  {'a': 1, 'b': 0},
                  gameId: gameId)
              .single
              .catalogId,
      };
      expect(seen, {'plus_10s', 'free_pass', 'reversed'});
    });
  });

  group('vivier', () {
    test(
        'Personnalisé : les actifs en Cartouche seulement ; vivier vide : rien',
        () {
      final rules = FiestaRules(
        mode: FiestaMode.custom,
        boostCount: 1,
        modifiers: {
          'plus_10s': cartridge(),
          'free_pass': cartridge().copyWith(active: false),
          'reversed': ModifierSetting(
              active: true, rounds: const {1, 2}, mode: ModifierMode.draw),
        },
      );
      for (final gameId in gameIds) {
        expect(gifts(rules, {'a': 2, 'b': 0}, gameId: gameId).single.catalogId,
            'plus_10s');
      }
      expect(gifts(boosted([]), {'a': 2, 'b': 0}), isEmpty);
    });

    test('Auto : tout ce qui peut être cartouche, jamais « Une seule réponse »',
        () {
      final pool = boostPool(
        rules: autoRules(oneAnswer: true),
        nextRound: 3,
        roundRules: const [],
        teamId: 'b',
        blockableTeamIds: allBlockable,
      ).map((d) => d.id);
      expect(pool, isNot(contains('one_answer')));
      expect(pool, containsAll(['plus_10s', 'minus_10s', 'mime_no_arms']));
      expect(autoRules(oneAnswer: false).boostCount, 1);
    });

    test('un mime seulement si M3 suit, la parole jamais avant M3', () {
      final mime = boosted(['mime_no_arms']);
      expect(gifts(mime, {'a': 2, 'b': 0}, finishedRound: 1), isEmpty);
      expect(gifts(mime, {'a': 2, 'b': 0}, finishedRound: 2).single.round, 3);
      final speech = boosted(['other_language']);
      expect(gifts(speech, {'a': 2, 'b': 0}, finishedRound: 1), hasLength(1));
      expect(gifts(speech, {'a': 2, 'b': 0}, finishedRound: 2), isEmpty);
    });

    test(
        'compatible avec les règles de la manche : ni le même, ni incompatible',
        () {
      expect(
          gifts(boosted(['reversed']), {'a': 2, 'b': 0},
              roundRules: [rule('reversed', 2)]),
          isEmpty);
      expect(
          gifts(boosted(['two_words']), {'a': 2, 'b': 0},
              roundRules: [rule('no_pass', 2)]),
          isEmpty);
      expect(
          gifts(boosted(['mime_no_arms']), {'a': 2, 'b': 0},
              finishedRound: 2, roundRules: [rule('draw', 3)]),
          isEmpty);
    });

    test('« Bloquer un devineur » seulement si une AUTRE équipe a 3 joueurs',
        () {
      final block = boosted(['block_guesser']);
      expect(gifts(block, {'a': 2, 'b': 0}, blockable: {'a'}), hasLength(1));
      expect(gifts(block, {'a': 2, 'b': 0}, blockable: {'b'}), isEmpty);
      expect(gifts(block, {'a': 2, 'b': 0}, blockable: const {}), isEmpty);
    });
  });

  group('plan de transition', () {
    test(
        '`apply` remplace les règles, garde les malus infligés, ajoute le gagné',
        () {
      const sent = ModifierInstance(
        catalogId: 'reversed',
        scope: ModifierScope.turn,
        target: ModifierTarget.team,
        teamId: 'a',
        charges: 0,
        nature: ModifierNature.malus,
        round: 1,
        fromTeamId: 'b',
      );
      final rules = boosted(['plus_10s']).copyWith(drawCount: 1, modifiers: {
        'plus_10s': cartridge(),
        'no_pass': ModifierSetting(
            active: true, rounds: const {1}, mode: ModifierMode.draw),
        'one_answer': ModifierSetting(
            active: true, rounds: const {2}, mode: ModifierMode.draw),
      });
      final before = FiestaState(
        rules: rules,
        active: [rule('no_pass', 1), sent],
        earned: const [
          EarnedCartridge(catalogId: 'plus_10s', teamId: 'z', round: 1)
        ],
      );
      final after = planRoundTransition(
        fiesta: before,
        gameId: 'g',
        finishedRound: 1,
        scores: {'a': 3, 'b': 1},
        blockableTeamIds: const {},
      )!
          .apply(before);
      expect(after.active.map((m) => '${m.catalogId}@${m.round}'),
          ['reversed@1', 'one_answer@2']);
      expect(after.earned.map((e) => (e.catalogId, e.teamId)),
          [('plus_10s', 'z'), ('plus_10s', 'b')]);
    });

    test('après M3 : pas de plan', () {
      expect(
          planRoundTransition(
            fiesta: FiestaState(rules: allCartridges),
            gameId: 'g',
            finishedRound: 3,
            scores: {'a': 3, 'b': 1},
            blockableTeamIds: const {},
          ),
          isNull);
    });
  });

  group('ensembles fournis', () {
    FiestaRules provided(String id) =>
        kProvidedEnsembles.firstWhere((e) => e.id == id).rules;
    Map<String, (ModifierMode, int)> active(FiestaRules r) => {
          for (final e in r.modifiers.entries)
            if (e.value.active) e.key: (e.value.mode, e.value.charges),
        };

    test('Fiesta classique : bonus, −10 s et blocage gagnés seulement', () {
      final r = provided('provided_classic');
      expect(r.boostCount, 1);
      expect(r.drawCount, 1);
      final a = active(r);
      for (final id in kCartridgeOnlyIds) {
        expect(a[id], (ModifierMode.cartridge, 0), reason: id);
      }
      for (final id in ['no_pass', 'reversed', 'other_language']) {
        expect(a[id]!.$1, ModifierMode.draw, reason: id);
      }
      // Plus rien en « Toujours » : tout passe par le tirage.
      expect(a['draw']!.$1, ModifierMode.draw);
      expect(a['one_answer']!.$1, ModifierMode.draw);
      expect(a.length, kCartridgeOnlyIds.length + 5);
      expect(a.values.map((v) => v.$1), isNot(contains(ModifierMode.always)));
    });

    test(
        'Explosif et L\'injustice : tout en cartouche, hors une seule réponse, '
        'TOUS les mimes', () {
      for (final (id, charges, boost) in [
        ('provided_explosive', 3, 0),
        ('provided_injustice', 0, 3),
      ]) {
        final r = provided(id);
        expect(r.boostCount, boost);
        final a = active(r);
        expect(a.containsKey('one_answer'), isFalse);
        expect(a.keys.where((m) => modifierById(m)!.mimeFamily).toSet(), {
          for (final def in kModifierCatalog)
            if (def.mimeFamily) def.id,
        });
        expect(a.containsKey('plus_10s'), isTrue);
        expect(a.values.toSet(), {(ModifierMode.cartridge, charges)});
      }
    });

    test('coup de pouce des autres fournis : 0', () {
      for (final id in ['pro', 'straight', 'pictionary', 'bilingual']) {
        expect(provided('provided_$id').boostCount, 0, reason: id);
      }
    });

    test('tous dans les bornes de l\'éditeur', () {
      for (final e in kProvidedEnsembles) {
        for (final m in e.rules.modifiers.entries) {
          expect(m.value.charges, lessThanOrEqualTo(maxCartridges(m.key)),
              reason: '${e.name} / ${m.key}');
        }
      }
    });

    test(
        'nouvel ensemble : cartouches à 1, Passe gratuite à 2, coup de pouce à 1',
        () {
      final r = defaultEnsembleRules('X');
      expect(r.boostCount, 1);
      expect(r.drawCount, 1);
      expect(active(r), {
        'minus_10s': (ModifierMode.cartridge, 1),
        'reversed': (ModifierMode.cartridge, 1),
        'mime_no_arms': (ModifierMode.cartridge, 1),
        'free_pass': (ModifierMode.cartridge, 2),
        'double_points': (ModifierMode.cartridge, 1),
        'one_answer': (ModifierMode.always, 1),
      });
    });
  });
}
