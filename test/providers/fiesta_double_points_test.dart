import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';

import '../helpers/test_prefs.dart';

/// [names] joueurs (1 mot chacun) répartis en 2 équipes.
Future<GameProvider> givenReadyProvider(List<String> names) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in names) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['mot-$name']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Personnalisé : « Mot compte double » tiré pour tous à chaque manche, seul
/// candidat, 1 charge.
final doubleEveryRound = FiestaRules(
  mode: FiestaMode.custom,
  drawCount: 1,
  modifiers: {
    'double_points': ModifierSetting(
      active: true,
      arrival: ModifierArrival.draw,
      startRound: 1,
      charges: 1,
    ),
  },
);

int teamScore(GameProvider p, String teamId) =>
    p.teams.firstWhere((t) => t.id == teamId).score;

List<int> teamRounds(GameProvider p, String teamId) =>
    p.teams.firstWhere((t) => t.id == teamId).scoreByRound;

void main() {
  test(
      '×2 : un mot refusé et le mot expiré validé à la vérification comptent '
      'pour 2 × 2 ; interrupteur relu après un kill, charge dépensée au départ '
      'seulement ; retour arrière = charge rendue et revalidation sans double '
      'comptage (AC2-AC5, AC7)', () async {
    var provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: doubleEveryRound);
    final teamId = provider.getCurrentTeam()!.id;

    // AC3 : allumer / éteindre ne dépense rien.
    provider.setDoublePoints(true);
    provider.setDoublePoints(false);
    provider.setDoublePoints(true);
    expect(provider.doublePointsLeft, 1);

    // AC7 : app tuée avant le départ.
    await pumpEventQueue();
    provider = GameProvider();
    await pumpEventQueue();
    expect(provider.isDoublePointsArmed, isTrue);
    expect(provider.doublePointsLeft, 1);

    provider.startTurn();
    provider.startTurnTimer();
    expect(provider.doublePointsLeft, 0);
    expect(provider.isDoublePointsOn, isTrue);

    provider.markWordAsGuessed();
    provider.markWordAsGuessed();
    provider.endTurn();
    final guessed = provider.game.wordsGuessedThisTurn;
    final validated = [guessed.first, provider.game.expiredWord!];
    provider.savePreValidationState(validated);
    provider.validateWords(validated);
    expect(teamScore(provider, teamId), 4);
    expect(teamRounds(provider, teamId).first, 4);

    // AC4 : l'équipe suivante arme son ×2, puis on revient en arrière.
    final nextTeamId = provider.getCurrentTeam()!.id;
    provider.setDoublePoints(true);
    provider.restorePreValidationState();
    expect(teamScore(provider, teamId), 0);
    expect(provider.isDoublePointsOn, isTrue); // le tour joué reste à ×2

    // AC5 : revalidation avec un seul mot.
    provider.savePreValidationState([guessed.first]);
    provider.validateWords([guessed.first]);
    expect(teamScore(provider, teamId), 2);
    expect(teamRounds(provider, teamId).first, 2);
    expect(provider.getCurrentTeam()!.id, nextTeamId);
    expect(provider.isDoublePointsArmed, isFalse);
    expect(provider.doublePointsLeft, 1);
  });

  test(
      'Continuation de fin de manche : même tour, toujours ×2, sans dépenser '
      'la charge de la nouvelle manche ; récap « Bonus utilisés » (AC6, AC8)',
      () async {
    final provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: doubleEveryRound);
    final teamId = provider.getCurrentTeam()!.id;
    provider.setDoublePoints(true);
    provider.startTurn();
    provider.startTurnTimer();
    while (provider.game.currentWord != null) {
      provider.markWordAsGuessed();
    }
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(teamRounds(provider, teamId), [8, 0, 0]);

    provider.nextRound();
    expect(provider.getCurrentTeam()!.id, teamId);
    expect(provider.isDoublePointsOn, isTrue);
    expect(provider.doublePointsLeft, 1); // charge de M2 intacte

    provider.startTurn();
    provider.startTurnTimer();
    expect(provider.doublePointsLeft, 1);
    provider.markWordAsGuessed();
    provider.endTurn();
    final word = provider.game.wordsGuessedThisTurn.first;
    provider.savePreValidationState([word]);
    provider.validateWords([word]);
    expect(teamRounds(provider, teamId), [8, 2, 0]);
    expect(provider.isDoublePointsArmed, isFalse);

    final recap = provider.modifierRecap.last;
    expect(recap.title, 'Bonus utilisés');
    expect(recap.detail,
        'Mot compte double, ${provider.getTeamById(teamId)!.name} en M1');
  });

  test(
      'Classique : l\'interrupteur est sans effet, 1 mot = 1 point, aucune '
      'clé Fiesta écrite', () async {
    final provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame();
    final teamId = provider.getCurrentTeam()!.id;
    provider.setDoublePoints(true);
    expect(provider.isDoublePointsArmed, isFalse);

    provider.startTurn();
    provider.startTurnTimer();
    provider.markWordAsGuessed();
    provider.markWordAsGuessed();
    provider.endTurn();
    final guessed = provider.game.wordsGuessedThisTurn;
    provider.validateWords(guessed);
    expect(teamScore(provider, teamId), 2);
    expect(provider.game.toJson().containsKey('fiesta'), isFalse);
  });
}
