import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/game_state.dart';
import 'package:guess_it_all_mobile/models/stats_aggregation.dart';

HistoryEntry tour({
  required String joueur,
  int round = 1,
  int devines = 0,
  int temps = 30,
}) =>
    HistoryEntry(
      round: round,
      turn: 1,
      teamId: 'equipe',
      playerId: joueur,
      wordsGuessed: List.generate(devines, (i) => 'mot$i'),
      wordsInvalidated: const [],
      wordsPassed: const [],
      timeSpent: temps,
    );

void main() {
  group('Classement — mots devinés', () {
    test('additionne les tours d\'un même joueur, du meilleur au moins bon',
        () {
      final rows = guessedWordsRanking([
        tour(joueur: 'a', devines: 3),
        tour(joueur: 'b', devines: 5),
        tour(joueur: 'a', devines: 4),
      ]);

      expect(rows.map((r) => r.playerId), ['a', 'b']);
      expect(rows.first.value, 7);
      expect(rows.first.label, '7');
    });

    test('le filtre par manche ne compte que cette manche', () {
      // 🔴 C'est LE paramètre qui remplace un builder recopié : avant, la
      // version « manche N » était une copie intégrale de la version « partie
      // entière », au `.where` près.
      final history = [
        tour(joueur: 'a', round: 1, devines: 10),
        tour(joueur: 'a', round: 2, devines: 1),
        tour(joueur: 'b', round: 2, devines: 4),
      ];

      expect(guessedWordsRanking(history, round: 2).map((r) => r.playerId),
          ['b', 'a']);
      expect(guessedWordsRanking(history, round: 1).single.value, 10);
      expect(guessedWordsRanking(history).first.playerId, 'a',
          reason: 'sans filtre, a mène avec 11');
    });

    test('à égalité, l\'ordre est stable d\'un affichage à l\'autre', () {
      // Sans départage, l'ordre suivait celui d'insertion dans une Map : deux
      // ouvertures de l'écran pouvaient donner deux podiums différents.
      final rows = guessedWordsRanking([
        tour(joueur: 'zoe', devines: 2),
        tour(joueur: 'alex', devines: 2),
      ]);

      expect(rows.map((r) => r.playerId), ['alex', 'zoe']);
    });

    test('un historique vide ne lève pas', () {
      expect(guessedWordsRanking(const []), isEmpty);
    });
  });

  group('Classement — temps moyen par mot', () {
    test('le plus rapide arrive en tête', () {
      final rows = averageTimePerWordRanking([
        tour(joueur: 'lent', devines: 2, temps: 30), // 15 s/mot
        tour(joueur: 'rapide', devines: 6, temps: 30), // 5 s/mot
      ]);

      expect(rows.map((r) => r.playerId), ['rapide', 'lent']);
      expect(rows.first.label, '5.0s');
    });

    test('un tour sans aucun mot deviné est ignoré', () {
      // Sinon sa durée pénaliserait le joueur pour un tour où il ne pouvait
      // rien marquer — et un joueur n'ayant JAMAIS marqué diviserait par zéro.
      final rows = averageTimePerWordRanking([
        tour(joueur: 'a', devines: 2, temps: 20), // 10 s/mot
        tour(joueur: 'a', devines: 0, temps: 30), // ignoré
        tour(joueur: 'bredouille', devines: 0, temps: 30),
      ]);

      expect(rows.map((r) => r.playerId), ['a']);
      expect(rows.single.value, 10);
    });

    test('le filtre par manche s\'applique aussi ici', () {
      final history = [
        tour(joueur: 'a', round: 1, devines: 1, temps: 30),
        tour(joueur: 'a', round: 3, devines: 10, temps: 30),
      ];

      expect(averageTimePerWordRanking(history, round: 1).single.value, 30);
      expect(averageTimePerWordRanking(history, round: 3).single.value, 3);
    });

    test('un historique vide ne lève pas', () {
      expect(averageTimePerWordRanking(const []), isEmpty);
    });
  });
}
