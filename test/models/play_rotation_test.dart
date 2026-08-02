import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/play_rotation.dart';

/// Réimplémentation LITTÉRALE de l'ancienne logique, sur une liste matérialisée.
///
/// Sert d'oracle : la nouvelle version dérivée doit lui être équivalente sur
/// tous les tours d'une partie réelle. C'est ce qui rend le passage
/// « matérialisé -> dérivé » vérifiable au lieu d'être une conviction.
({int teamIndex, int playerIndex}) legacyRotation({
  required List<int> teamCycle,
  required List<int> playerCycle,
  required int turnIndex,
}) {
  final teamPlayOrder = <int>[for (var i = 0; i < 1000; i++) ...teamCycle];
  final playerOrder = <int>[for (var i = 0; i < 1000; i++) ...playerCycle];

  final teamIndex = teamPlayOrder[turnIndex];

  var teamPlayCount = 0;
  for (var i = 0; i <= turnIndex; i++) {
    if (teamPlayOrder[i] == teamIndex) teamPlayCount++;
  }

  return (
    teamIndex: teamIndex,
    playerIndex: playerOrder[(teamPlayCount - 1) % playerOrder.length],
  );
}

void main() {
  group('Rotation dérivée — équivalence avec l\'ancienne version matérialisée',
      () {
    test('mêmes équipe et joueur sur 200 tours, pour toutes les tailles', () {
      // Toutes les configurations réellement possibles : 2 à 4 équipes,
      // 1 à 6 joueurs par équipe.
      for (var teams = 2; teams <= 4; teams++) {
        for (var playersPerTeam = 1; playersPerTeam <= 6; playersPerTeam++) {
          // Cycles volontairement NON triés (l'ordre est mélangé en vrai), mais
          // qui restent des PERMUTATIONS : c'est la précondition de la
          // dérivation, et c'est ce que produit `_generatePlayOrder` (shuffle
          // d'indices distincts).
          final teamCycle = List<int>.generate(teams, (i) => (i + 1) % teams);
          final playerCycle = List<int>.generate(
              playersPerTeam, (i) => (i + playersPerTeam - 1) % playersPerTeam);

          for (var turn = 0; turn < 200; turn++) {
            final expected = legacyRotation(
              teamCycle: teamCycle,
              playerCycle: playerCycle,
              turnIndex: turn,
            );

            expect(
              teamIndexAtTurn(
                teamPlayOrder: teamCycle,
                cycleLength: teams,
                turnIndex: turn,
              ),
              expected.teamIndex,
              reason:
                  'équipe — $teams équipes, $playersPerTeam joueurs, tour $turn',
            );

            expect(
              playerIndexAtTurn(
                playerOrderForTeam: playerCycle,
                cycleLength: teams,
                turnIndex: turn,
              ),
              expected.playerIndex,
              reason:
                  'joueur — $teams équipes, $playersPerTeam joueurs, tour $turn',
            );
          }
        }
      }
    });

    test(
        'l\'ancien format persisté (liste répétée 1000x) donne le même résultat',
        () {
      // Les parties EN COURS sur les téléphones portent la liste matérialisée.
      // Indexer modulo doit donner exactement la même rotation, sinon la reprise
      // d'une partie changerait de joueur en cours de route.
      final teamCycle = [2, 0, 1];
      final materialized = <int>[for (var i = 0; i < 1000; i++) ...teamCycle];

      for (var turn = 0; turn < 150; turn++) {
        expect(
          teamIndexAtTurn(
            teamPlayOrder: materialized,
            cycleLength: teamCycle.length,
            turnIndex: turn,
          ),
          teamIndexAtTurn(
            teamPlayOrder: teamCycle,
            cycleLength: teamCycle.length,
            turnIndex: turn,
          ),
        );
      }
    });
  });

  group('Rotation dérivée — propriétés', () {
    test('chaque équipe joue une fois par tour de table', () {
      const teams = 3;
      final cycle = [1, 2, 0];

      final vus = <int>{};
      for (var turn = 0; turn < teams; turn++) {
        vus.add(teamIndexAtTurn(
            teamPlayOrder: cycle, cycleLength: teams, turnIndex: turn));
      }

      expect(vus.length, teams,
          reason: 'aucune équipe sautée ni jouée deux fois');
    });

    test('le compteur de passages augmente d\'un par tour de table', () {
      expect(teamPlayCountAtTurn(cycleLength: 3, turnIndex: 0), 1);
      expect(teamPlayCountAtTurn(cycleLength: 3, turnIndex: 2), 1);
      expect(teamPlayCountAtTurn(cycleLength: 3, turnIndex: 3), 2);
      expect(teamPlayCountAtTurn(cycleLength: 3, turnIndex: 5), 2);
      expect(teamPlayCountAtTurn(cycleLength: 3, turnIndex: 6), 3);
    });

    test('les entrées dégénérées ne font pas planter', () {
      expect(
          teamIndexAtTurn(
              teamPlayOrder: const [], cycleLength: 0, turnIndex: 7),
          0);
      expect(
          playerIndexAtTurn(
              playerOrderForTeam: const [], cycleLength: 2, turnIndex: 7),
          0);
    });
  });
}
