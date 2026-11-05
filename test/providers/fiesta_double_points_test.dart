import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

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

/// Personnalisé : « Mot compte double » en cartouche, 1 par équipe pour la
/// partie.
final doubleOnce = FiestaRules(
  mode: FiestaMode.custom,
  drawCount: 0,
  modifiers: {
    'double_points': ModifierSetting(
      active: true,
      rounds: const {1, 2, 3},
      mode: ModifierMode.cartridge,
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
    await provider.startGame(fiesta: doubleOnce);
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
      'la charge de la nouvelle manche ; récap « Cartouches utilisées » (AC6, AC8)',
      () async {
    final provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: doubleOnce);
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
    // Dépensé sur ce tour : il tient, sans se rallumer ni se recompter.
    expect(provider.doublePointsLeft, 0);
    provider.setDoublePoints(true);
    expect(provider.isDoublePointsOn, isTrue);

    provider.startTurn();
    provider.startTurnTimer();
    expect(
        provider.game.fiesta!.chargesUsed.where((u) => u.round == 2), isEmpty);
    provider.markWordAsGuessed();
    provider.endTurn();
    final word = provider.game.wordsGuessedThisTurn.first;
    provider.savePreValidationState([word]);
    provider.validateWords([word]);
    expect(teamRounds(provider, teamId), [8, 2, 0]);
    expect(provider.isDoublePointsArmed, isFalse);

    final recap = provider.modifierRecap.last;
    expect(recap.title, 'Cartouches utilisées');
    expect(recap.detail,
        'Mot compte double, ${provider.getTeamById(teamId)!.name} en M1');
  });

  test(
      'Continuation NON activée en fin de M1 : la charge s\'y allume et compte '
      'pour la continuation seule (retours Fiesta v3.1)', () async {
    final provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: doubleOnce);
    final teamId = provider.getCurrentTeam()!.id;
    void playOne(List<String> Function(List<String>) validate, {int n = 1}) {
      provider.startTurn();
      provider.startTurnTimer();
      for (var i = 0; i < n; i++) {
        provider.markWordAsGuessed();
      }
      if (provider.game.currentScreen != AppConstants.screenVerification)
        provider.endTurn();
      final words = validate(provider.game.wordsGuessedThisTurn);
      provider.savePreValidationState(words);
      provider.validateWords(words);
    }

    playOne((w) => w, n: 4);
    expect(teamRounds(provider, teamId), [4, 0, 0]);

    provider.nextRound();
    expect(provider.getCurrentTeam()!.id, teamId);
    expect(provider.game.turnBonusTime, isNot(anyOf(isNull, 0)));
    provider.setDoublePoints(true);
    expect(provider.isDoublePointsArmed, isTrue);
    playOne((w) => w); // la continuation : 2 points
    expect(teamRounds(provider, teamId), [4, 2, 0]);
    expect(provider.isDoublePointsArmed, isFalse, reason: 'fin du tour');
    playOne((w) => const []); // l'autre équipe

    expect(provider.getCurrentTeam()!.id, teamId);
    expect(provider.doublePointsLeft, 0, reason: 'dépensée en continuation');
    playOne((w) => w);
    expect(teamRounds(provider, teamId), [4, 3, 0]);
    expect(
        provider.game.fiesta!.chargesUsed
            .where((u) => u.teamId == teamId && u.round == 2),
        hasLength(1));
  });

  test(
      'Évolution des scores : le dernier point de chaque équipe = son score, '
      'avec ×2 et continuation ; la clé n\'est écrite que si elle diffère '
      'du nombre de mots (epic fix B3)', () async {
    final provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: doubleOnce);
    provider.setDoublePoints(true);
    provider.startTurn();
    provider.startTurnTimer();
    while (provider.game.currentWord != null) {
      provider.markWordAsGuessed();
    }
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    provider.nextRound();
    provider.startTurn(); // continuation, toujours ×2
    provider.startTurnTimer();
    provider.markWordAsGuessed();
    provider.endTurn();
    final word = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(word);
    provider.validateWords(word);

    for (final team in provider.teams) {
      final lastPoint = provider.game.history
          .where((h) => h.teamId == team.id)
          .fold(0, (sum, h) => sum + h.points);
      expect(lastPoint, team.score, reason: team.name);
    }
    final json = provider.game.history.map((h) => h.toJson()).toList();
    expect(json.every((h) => h['pointsScored'] == 2 * h['wordsGuessed'].length),
        isTrue);
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
    expect(provider.game.history.single.toJson().containsKey('pointsScored'),
        isFalse);
  });
}
