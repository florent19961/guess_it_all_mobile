import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/turn_time.dart';

void main() {
  group('composeTurnSeconds', () {
    test('sans modificateur : la base (Classique inchangé)', () {
      final time = composeTurnSeconds(baseSeconds: 30);
      expect(time.total, 30);
      expect(time.lines.single.seconds, 30);
    });

    test('+10 s, −10 s et les deux : ils se compensent', () {
      expect(composeTurnSeconds(baseSeconds: 30, plus10sCount: 1).total, 40);
      expect(composeTurnSeconds(baseSeconds: 30, minus10sCount: 2).total, 10);
      expect(
          composeTurnSeconds(baseSeconds: 30, plus10sCount: 1, minus10sCount: 1)
              .total,
          30);
    });

    test('plancher de 10 s après tous les malus, +10 s compris', () {
      expect(composeTurnSeconds(baseSeconds: 20, minus10sCount: 3).total,
          kTurnFloorSeconds);
      expect(
          composeTurnSeconds(baseSeconds: 15, plus10sCount: 1, minus10sCount: 3)
              .total,
          kTurnFloorSeconds);
      // Le plancher vaut pour le total, le +10 s s'ajoute avant.
      expect(
          composeTurnSeconds(baseSeconds: 15, plus10sCount: 1, minus10sCount: 1)
              .total,
          15);
    });

    test('continuation : ses secondes, + 10 s allumés ; le −10 s ne compte pas',
        () {
      final carried = composeTurnSeconds(
          baseSeconds: 30, carriedSeconds: 7, minus10sCount: 1);
      expect(carried.total, 7, reason: 'sous le plancher aussi : exact');
      expect(carried.lines.single.label, 'Temps reporté');

      final boosted = composeTurnSeconds(
          baseSeconds: 30,
          carriedSeconds: 7,
          plus10sCount: 1,
          minus10sCount: 1);
      expect(boosted.total, 17);
      expect(boosted.lines.map((l) => l.seconds), [7, 10]);
    });
  });
}
