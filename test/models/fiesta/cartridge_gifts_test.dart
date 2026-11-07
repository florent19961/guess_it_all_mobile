import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/cartridge_gifts.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/round_transition.dart';

ModifierInstance rule(String id, {int round = 2}) => ModifierInstance(
      catalogId: id,
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: round,
    );

ModifierInstance sent(String id,
        {required String to, String from = 'a', int round = 1}) =>
    ModifierInstance(
      catalogId: id,
      scope: ModifierScope.turn,
      target: ModifierTarget.team,
      teamId: to,
      charges: 0,
      nature: ModifierNature.malus,
      round: round,
      fromTeamId: from,
    );

List<String> pool(
  FiestaRules rules, {
  int nextRound = 2,
  List<ModifierInstance> roundRules = const [],
  Set<String> blockable = const {'b'},
}) =>
    giftPool(
      rules: rules,
      nextRound: nextRound,
      roundRules: roundRules,
      teamId: 'a',
      blockableTeamIds: blockable,
    ).map((d) => d.id).toList();

List<EarnedCartridge> gifts(
  FiestaRules rules, {
  int finishedRound = 1,
  Map<String, int> scores = const {'a': 10, 'b': 5},
  int totalWords = 40,
  String gameId = 'g',
  List<ModifierInstance> roundRules = const [],
}) =>
    roundGifts(
      rules: rules,
      gameId: gameId,
      finishedRound: finishedRound,
      scores: scores,
      totalWords: totalWords,
      roundRules: roundRules,
      blockableTeamIds: const {'a', 'b'},
    );

void main() {
  group('Équilibrer la partie', () {
    test('selon l\'écart rapporté aux mots : seuils 10 % et 25 %', () {
      int of(int gap) => balanceGiftCount(gap: gap, totalWords: 40);
      expect(of(0), 0);
      expect(of(1), 1);
      expect(of(3), 1, reason: '7,5 %');
      expect(of(4), 2, reason: '10 % pile');
      expect(of(10), 2, reason: '25 % pile');
      expect(of(11), 3);
      expect(of(40), 3);
    });

    test('remplace le nombre fixe, rien pour le leader', () {
      final g = gifts(FiestaRules(balance: true, trailingCount: 5),
          scores: const {'a': 20, 'b': 18, 'c': 4});
      int count(String team) => g.where((e) => e.teamId == team).length;
      expect([count('a'), count('b'), count('c')], [0, 1, 3]);
    });
  });

  group('Vivier du hasard', () {
    test('tout le catalogue possible, HORS Toujours ; compteurs sans effet',
        () {
      final all = pool(FiestaRules());
      expect(all, contains('one_answer'));
      expect(all, contains('block_giver'));
      expect(all, contains('plus_10s'));
      expect(all, isNot(contains('mime_no_arms')), reason: 'mime en M3');
      final without = pool(FiestaRules(modifiers: const {
        'reversed': ModifierSetting(always: true),
      }));
      expect(without, isNot(contains('reversed')));
    });

    test('possible à la manche suivante, compatible avec ses règles', () {
      final m3 = pool(FiestaRules(), nextRound: 3);
      expect(m3, contains('mime_no_arms'));
      expect(m3, isNot(contains('other_language')));
      final underNoPass = pool(FiestaRules(), roundRules: [rule('no_pass')]);
      expect(underNoPass, isNot(contains('no_pass')));
      expect(underNoPass, isNot(contains('free_pass')));
      final underSheet = pool(FiestaRules(),
          nextRound: 3, roundRules: [rule('mime_under_sheet', round: 3)]);
      expect(underSheet, contains('sounds_only'));
      expect(underSheet, isNot(contains('mime_no_arms')));
    });

    test('Bloquer un devineur seulement si une AUTRE équipe a 3 joueurs', () {
      expect(pool(FiestaRules(), blockable: {'a'}),
          isNot(contains('block_guesser')));
      expect(pool(FiestaRules(), blockable: {'a'}), contains('block_giver'));
      expect(pool(FiestaRules(), blockable: {'b'}), contains('block_guesser'));
    });
  });

  group('Distribution', () {
    test('allCount : à toutes les équipes, M1 comprise', () {
      final g = gifts(FiestaRules(allCount: 2),
          finishedRound: 0, scores: const {'a': 0, 'b': 0});
      expect(g.where((e) => e.teamId == 'a'), hasLength(2));
      expect(g.where((e) => e.teamId == 'b'), hasLength(2));
      expect(g.every((e) => e.round == 1), isTrue);
    });

    test('trailingCount : après M1 et M2, non-leaders, égalité = personne', () {
      final rules = FiestaRules(trailingCount: 2);
      expect(gifts(rules, scores: const {'a': 5, 'b': 5}), isEmpty);
      expect(
          gifts(rules, scores: const {'a': 9, 'b': 9, 'c': 1}).map((e) {
            return e.teamId;
          }).toSet(),
          {'c'},
          reason: 'co-leaders : rien');
      expect(gifts(rules, finishedRound: 0, scores: const {'a': 0, 'b': 3}),
          isEmpty);
    });

    test('allCount + trailing se cumulent', () {
      final g = gifts(FiestaRules(allCount: 2, trailingCount: 3));
      expect(g.where((e) => e.teamId == 'b'), hasLength(5));
      expect(g.where((e) => e.teamId == 'a'), hasLength(2));
    });

    test('avec remise : la même cartouche peut sortir deux fois', () {
      // Vivier bien plus grand que 3 : l'ancien tirage donnait 3 distinctes.
      final rules = FiestaRules(allCount: 3);
      expect(pool(rules).length, greaterThan(3));
      final anyTwice = List.generate(40, (i) => 'g$i').any((id) {
        final ids = gifts(rules, gameId: id)
            .where((e) => e.teamId == 'a')
            .map((e) => e.catalogId);
        return ids.toSet().length < ids.length;
      });
      expect(anyTwice, isTrue);
    });

    test('poids : Mot compte double sort 3 fois moins qu\'une autre', () {
      final counts = <String, int>{};
      for (var i = 0; i < 3000; i++) {
        final g = gifts(FiestaRules(allCount: 1),
            gameId: 'g$i', scores: const {'a': 0});
        counts.update(g.single.catalogId, (n) => n + 1, ifAbsent: () => 1);
      }
      final others = counts.entries.where((e) => e.key != 'double_points');
      final mean = others.fold<int>(0, (n, e) => n + e.value) / others.length;
      expect(others, hasLength(pool(FiestaRules()).length - 1),
          reason: 'tout le vivier sort');
      // Attendu : 1/3. Graines fixes, donc résultat stable.
      expect(counts['double_points']! / mean, inInclusiveRange(0.25, 0.45));
      // Les autres sont à égalité entre elles.
      for (final e in others) {
        expect(e.value / mean, inInclusiveRange(0.7, 1.3), reason: e.key);
      }
    });

    test('déterministe par (gameId, manche, équipe)', () {
      final rules = FiestaRules(allCount: 3);
      List<String> teamB(String gameId, int finished) =>
          gifts(rules, gameId: gameId, finishedRound: finished)
              .where((e) => e.teamId == 'b')
              .map((e) => e.catalogId)
              .toList();
      expect(teamB('g', 1), teamB('g', 1));
      final variants = {for (var i = 0; i < 12; i++) teamB('g$i', 1).join()};
      expect(variants.length, greaterThan(1));
      // Le tirage d'une équipe ne dépend ni du score ni des autres équipes.
      expect(
          gifts(rules, scores: const {'b': 0}).map((e) => e.catalogId).toList(),
          teamB('g', 1));
    });

    test('vivier d\'une seule cartouche : elle revient ; vide : rien', () {
      // Tout en Toujours sauf reversed.
      final rules = FiestaRules(allCount: 3, modifiers: {
        for (final def in kModifierCatalog)
          if (def.id != 'reversed') def.id: const ModifierSetting(always: true),
      });
      final g = gifts(rules).where((e) => e.teamId == 'a');
      expect(g.map((e) => e.catalogId), ['reversed', 'reversed', 'reversed']);
      expect(
          gifts(FiestaRules(allCount: 3, modifiers: {
            for (final def in kModifierCatalog)
              def.id: const ModifierSetting(always: true),
          })),
          isEmpty);
    });
  });

  group('Malus déjà envoyé au passage de manche', () {
    FiestaState withSent(ModifierInstance malus) => FiestaState(
          rules: FiestaRules(drawCount: 1, modifiers: const {
            'reversed': ModifierSetting(draw: true),
          }),
          active: [malus],
          chargesUsed: [
            ChargeUse(
                catalogId: malus.catalogId,
                teamId: malus.fromTeamId!,
                round: malus.round,
                targetTeamId: malus.teamId),
          ],
        );

    FiestaState cross(FiestaState f, {String? continuing, int finished = 1}) =>
        planRoundTransition(
          fiesta: f,
          gameId: 'g',
          finishedRound: finished,
          scores: const {'a': 0, 'b': 0},
          totalWords: 40,
          blockableTeamIds: const {},
          continuingTeamId: continuing,
        )!
            .apply(f);

    test('croise la règle tirée : RENDU à l\'envoyeur', () {
      final f = cross(withSent(sent('reversed', to: 'b')));
      expect(f.active.where((m) => m.fromTeamId != null), isEmpty);
      expect(f.chargesUsed, isEmpty);
    });

    test('impossible quand la cible rejoue : Autre langue en M3, RENDU', () {
      final f = cross(withSent(sent('other_language', to: 'b', round: 2)),
          finished: 2);
      expect(f.active.where((m) => m.fromTeamId != null), isEmpty);
      expect(f.chargesUsed, isEmpty);
    });

    test('déjà en cours sur le tour qui continue : tombe sans rien rendre', () {
      final f = cross(withSent(sent('other_language', to: 'b', round: 2)),
          finished: 2, continuing: 'b');
      expect(f.chargesUsed, hasLength(1));
      expect(
          modifiersForTurn(f.active, teamId: 'b', playerId: 'p', round: 3)
              .where((m) => m.fromTeamId != null),
          isEmpty);
    });

    test('sans conflit : il attend, rien de rendu', () {
      final f = cross(withSent(sent('no_pass', to: 'b')));
      expect(f.active.where((m) => m.fromTeamId != null), hasLength(1));
      expect(f.chargesUsed, hasLength(1));
    });
  });
}
