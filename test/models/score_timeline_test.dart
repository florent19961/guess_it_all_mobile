import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/game_state.dart';
import 'package:guess_it_all_mobile/models/score_timeline.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

HistoryEntry entry(int round, int turn, String team, int words,
        {int? points, bool continuation = false}) =>
    HistoryEntry(
      round: round,
      turn: turn,
      teamId: team,
      playerId: 'p',
      wordsGuessed: List.filled(words, 'w'),
      wordsInvalidated: const [],
      wordsPassed: const [],
      timeSpent: 1,
      isBonusContinuation: continuation,
      pointsScored: points,
    );

void main() {
  // a finit la manche 1 au tour 3 et continue en manche 2 (même tour).
  final history = [
    entry(1, 1, 'a', 2),
    entry(1, 2, 'b', 3),
    entry(1, 3, 'a', 1),
    entry(2, 3, 'a', 2, points: 4, continuation: true),
    entry(2, 4, 'b', 1),
    entry(3, 5, 'a', 1),
  ];

  test('scores cumulés tour par tour, continuation et double points compris',
      () {
    final t = buildScoreTimeline(teamIds: ['a', 'b'], history: history);
    expect(t.steps, 6);
    expect(t.series[0], [0, 2, 2, 3, 7, 7, 8]);
    expect(t.series[1], [0, 0, 3, 3, 3, 4, 4]);
    expect(t.maxScore, 8);
  });

  test('la continuation compte dans sa manche : séparateurs au bon endroit',
      () {
    final t = buildScoreTimeline(teamIds: ['a', 'b'], history: history);
    expect([for (final r in t.rounds) (r.round, r.start, r.end)],
        [(1, 0, 3), (2, 3, 5), (3, 5, 6)]);
  });

  test('une cartouche tombe au début de son tour, dans sa manche', () {
    final t = buildScoreTimeline(
        teamIds: ['a', 'b'],
        history: history,
        chargesUsed: const [
          ChargeUse(catalogId: 'double_points', teamId: 'b', round: 1, turn: 2),
          // Tour 3 : la manche départage la 1re partie de la continuation.
          ChargeUse(catalogId: 'plus_10s', teamId: 'a', round: 1, turn: 3),
          ChargeUse(catalogId: 'double_points', teamId: 'a', round: 2, turn: 3),
        ]);
    expect([for (final e in t.events) (e.step, e.teamIndex)],
        [(1, 1), (2, 0), (3, 0)]);
  });

  test('sans numéro de tour (ou tour introuvable) : en fin de manche', () {
    final t = buildScoreTimeline(
        teamIds: ['a', 'b'],
        history: history,
        chargesUsed: const [
          ChargeUse(catalogId: 'reversed', teamId: 'b', round: 1),
          ChargeUse(catalogId: 'reversed', teamId: 'b', round: 2, turn: 99),
          ChargeUse(catalogId: 'reversed', teamId: 'a', round: 3),
        ]);
    expect([for (final e in t.events) e.step], [3, 5, 6]);
  });

  test(
      'plusieurs cartouches au même endroit s\'empilent, équipe inconnue ignorée',
      () {
    final t = buildScoreTimeline(
        teamIds: ['a', 'b'],
        history: history,
        chargesUsed: const [
          ChargeUse(catalogId: 'double_points', teamId: 'a', round: 1, turn: 1),
          ChargeUse(catalogId: 'plus_10s', teamId: 'a', round: 1, turn: 1),
          ChargeUse(catalogId: 'plus_10s', teamId: 'b', round: 1, turn: 1),
          ChargeUse(catalogId: 'plus_10s', teamId: 'zzz', round: 1, turn: 1),
        ]);
    expect([for (final e in t.events) e.stack], [0, 1, 0]);
  });

  test('la courbe passe par chaque score sans dépasser ni reculer', () {
    final t = buildScoreTimeline(teamIds: ['a', 'b'], history: history);
    for (var team = 0; team < 2; team++) {
      for (var i = 0; i <= t.steps; i++) {
        expect(t.valueAt(team, i.toDouble()), t.series[team][i]);
      }
      var previous = 0.0;
      for (var x = 0.0; x <= t.steps; x += .05) {
        final v = t.valueAt(team, x);
        expect(v, greaterThanOrEqualTo(previous));
        previous = v;
      }
    }
  });

  test('partie sans historique : pas d\'étape, pas de crash', () {
    final t = buildScoreTimeline(teamIds: ['a'], history: const []);
    expect(t.steps, 0);
    expect(t.valueAt(0, 0), 0);
  });

  test('annonce finale : pluriel ou singulier', () {
    expect(revealHeadline('Les Moulins'), 'Les Moulins gagnent !');
    expect(revealHeadline('Bob'), 'Bob gagne !');
  });

  group('persistance', () {
    test('ChargeUse : tour relu, clé absente ou mal typée tolérée', () {
      const use = ChargeUse(catalogId: 'x', teamId: 'a', round: 2, turn: 7);
      expect(ChargeUse.tryFromJson(use.toJson())!.turn, 7);
      final old = {'catalogId': 'x', 'teamId': 'a', 'round': 2};
      expect(
          const ChargeUse(catalogId: 'x', teamId: 'a', round: 2).toJson(), old);
      expect(ChargeUse.tryFromJson(old)!.turn, isNull);
      expect(ChargeUse.tryFromJson({...old, 'turn': 'x'})!.turn, isNull);
    });

    test('GameState : clé écrite seulement une fois vue', () {
      expect(GameState().toJson().containsKey('scoreRevealSeen'), isFalse);
      final seen = GameState(scoreRevealSeen: true).toJson();
      expect(GameState.fromJson(seen).scoreRevealSeen, isTrue);
    });

    test(
        'partie déjà sur les résultats ou les stats à la relecture : pas de révélation',
        () {
      for (final screen in [
        AppConstants.screenResults,
        AppConstants.screenStats
      ]) {
        expect(GameState.fromJson({'currentScreen': screen}).scoreRevealSeen,
            isTrue);
      }
      expect(
          GameState.fromJson({'currentScreen': AppConstants.screenVerification})
              .scoreRevealSeen,
          isFalse);
    });
  });
}
