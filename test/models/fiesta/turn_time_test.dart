import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/turn_time.dart';

Map<String, int> due(List<CatchUpEntry> entries) =>
    {for (final e in entries) e.teamId: e.seconds};

void main() {
  group('Rattrapage — formule et plafonds', () {
    test('Auto, 14–8 après M1 : +3 s × 6 à la menée, −1 s × 6 au leader', () {
      final entries = computeCatchUp(
        rules: CatchUpRules.auto,
        round: 1,
        scores: {'rose': 14, 'bleue': 8},
      );
      expect(due(entries), {'rose': -6, 'bleue': 18});
      final leader = entries.singleWhere((e) => e.isLeader);
      expect((leader.gap, leader.perPoint), (6, 1));

      // AC2 : 30 + 18 = 48 s pour la menée, 30 − 6 = 24 s pour le leader.
      expect(composeTurnSeconds(baseSeconds: 30, catchUpSeconds: 18).total, 48);
      expect(
          composeTurnSeconds(baseSeconds: 30, leaderMalusSeconds: 6).total, 24);
    });

    test('après M2, k = 5 et le bonus plafonne à 30 ; le malus à 15', () {
      final entries = computeCatchUp(
        rules: CatchUpRules.auto,
        round: 2,
        scores: {'rose': 20, 'bleue': 8, 'verte': 2},
      );
      // Écart 12 → 5 × 12 = 60, plafonné ; écart 18 → plafonné aussi.
      // Leader : écart avec la 2ᵉ (12) → 1 × 12 = 12 (sous le plafond).
      expect(due(entries), {'rose': -12, 'bleue': 30, 'verte': 30});

      final capped = computeCatchUp(
        rules: CatchUpRules.auto,
        round: 2,
        scores: {'rose': 30, 'bleue': 0},
      );
      expect(due(capped), {'rose': -15, 'bleue': 30});
    });

    test(
        'égalité générale : rien ; co-leaders : tous en tête, malus sur la '
        'meilleure non-leader', () {
      expect(
          computeCatchUp(
            rules: CatchUpRules.auto,
            round: 1,
            scores: {'a': 7, 'b': 7, 'c': 7},
          ),
          isEmpty);

      final entries = computeCatchUp(
        rules: CatchUpRules.auto,
        round: 1,
        scores: {'a': 10, 'b': 10, 'c': 4},
      );
      expect(due(entries), {'a': -6, 'b': -6, 'c': 18});
    });

    test('Personnalisé tout à 0 = éteint ; Auto sans auto-calibrage = éteint',
        () {
      const off = CatchUpRules(b1: 0, b2: 0, cap: 0, mal: 0, malCap: 0);
      expect(computeCatchUp(rules: off, round: 1, scores: {'a': 9, 'b': 1}),
          isEmpty);
      expect(
          effectiveCatchUp(
              FiestaRules(mode: FiestaMode.auto, autoCalibrate: false)),
          isNull);
      expect(
          effectiveCatchUp(FiestaRules(mode: FiestaMode.custom, catchUp: off)),
          same(off));
    });
  });

  group('Durée du tour — composition', () {
    test('plancher de 10 s après tous les malus (AC6)', () {
      final time = composeTurnSeconds(
        baseSeconds: 20,
        leaderMalusSeconds: 15,
        minus10sCount: 1,
      );
      expect(time.total, 10);
      expect(time.lines.map((l) => l.seconds), [20, -15, -10]);
    });

    test(
        'une continuation garde exactement ses secondes, sans modificateur '
        '(Q5)', () {
      final time = composeTurnSeconds(
        baseSeconds: 30,
        carriedSeconds: 7,
        catchUpSeconds: 18,
        leaderMalusSeconds: 6,
        minus10sCount: 2,
      );
      expect(time.total, 7);
      expect(time.lines.map((l) => l.seconds), [7]);

      // Et sous le plancher aussi : 3 s reportées restent 3 s.
      expect(composeTurnSeconds(baseSeconds: 30, carriedSeconds: 3).total, 3);
    });
  });
}
