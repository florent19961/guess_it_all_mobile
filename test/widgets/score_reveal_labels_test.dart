import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/score_timeline.dart';
import 'package:guess_it_all_mobile/widgets/effects/score_reveal_chart.dart';

void main() {
  test(
      'étiquettes : à droite des têtes, sans chevauchement, règle des 5 joueurs',
      () {
    const top = 8.0;
    const bottom = 300.0;
    const heights = [45.0, 15.0, 30.0, 45.0];
    double yAt(double value) => bottom - value / 12 * (bottom - top);

    List<Offset> placed(List<List<int>> series, double progress) =>
        placeRevealLabels(
          timeline: ScoreTimeline(series: series, rounds: const []),
          progress: progress,
          headX: 100,
          yAt: yAt,
          heights: heights,
          top: top,
          bottom: bottom,
        );

    void expectStacked(List<Offset> labels) {
      final order = [0, 1, 2, 3]
        ..sort((a, b) => labels[a].dy.compareTo(labels[b].dy));
      // La moyenne du lissage laisse un arrondi flottant.
      expect(labels[order.first].dy, greaterThanOrEqualTo(top - 1e-9));
      expect(labels[order.last].dy + heights[order.last],
          lessThanOrEqualTo(bottom + 1e-9));
      for (var i = 1; i < order.length; i++) {
        expect(labels[order[i]].dy,
            greaterThan(labels[order[i - 1]].dy + heights[order[i - 1]]));
      }
    }

    // Courbes serrées qui ne se croisent pas : poussées à chaque image.
    const parallel = [
      [0, 4, 6, 8],
      [0, 3, 5, 7],
      [0, 2, 4, 6],
      [0, 1, 3, 5],
    ];
    for (var p = 0.0; p <= 1; p += .05) {
      final labels = placed(parallel, p);
      expectStacked(labels);
      expect(labels.every((l) => l.dx > 100), isTrue);
    }

    // Courbes qui se croisent : à la fin, plus rien du lissage ne traîne.
    const crossing = [
      [0, 9, 9, 9],
      [0, 0, 8, 12],
      [0, 0, 0, 0],
      [0, 5, 5, 6],
    ];
    expectStacked(placed(crossing, 1));
    expect(placed(crossing, .63), placed(crossing, .63),
        reason: 'fonction pure du progrès');
    final spread = placed(const [
      [0, 12],
      [0, 8],
      [0, 4],
      [0, 0],
    ], 1);
    expect(spread[1].dy + heights[1] / 2, closeTo(yAt(8), 1e-9),
        reason: 'sans voisine, l\'étiquette revient sur sa tête à la fin');

    // Plus de 5 joueurs dans une équipe : noms d'équipes pour toutes.
    const names = ['Les A', 'Les B'];
    List<String> five(String p) => [for (var i = 0; i < 5; i++) '$p$i'];

    expect(revealLabels(teamNames: names, players: [five('a'), five('b')]),
        ['a0, a1, a2, a3, a4', 'b0, b1, b2, b3, b4']);
    expect(
        revealLabels(teamNames: names, players: [
          five('a'),
          [...five('b'), 'b5']
        ]),
        names);
  });
}
