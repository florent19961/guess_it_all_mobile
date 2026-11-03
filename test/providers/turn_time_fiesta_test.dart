import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';

import '../helpers/test_prefs.dart';

/// Un provider prêt à lancer une partie : 2 joueurs, 2 équipes, 1 mot chacun,
/// réglages par défaut (30 s, pénalité de passe 5 s).
Future<GameProvider> givenReadyProvider() async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in ['Ana', 'Bob']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['mot-$name']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Une passe (−5 s) puis les 2 mots devinés : fin de manche avec 25 s
/// reportées, puis validation → transition.
void finishRoundWithCarryOver(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.passWord();
  provider.markWordAsGuessed();
  provider.markWordAsGuessed();
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
}

/// Un tour sans rien deviner, validé vide : passe la main.
void playEmptyTurn(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.endTurn();
  provider.savePreValidationState(const []);
  provider.validateWords(const []);
}

int allotted(GameProvider p) =>
    (p.game.turnEndTimestamp! - p.game.turnStartTimestamp!) ~/ 1000;

void main() {
  test(
      'Classique : durée inchangée seconde pour seconde, et le temps passé '
      'd\'une continuation est mesuré sur ses secondes reportées (AC1, AC7)',
      () async {
    final provider = await givenReadyProvider();
    await provider.startGame();
    expect(provider.turnTime.total, 30);

    finishRoundWithCarryOver(provider);
    expect(provider.game.turnBonusTime, 25);
    expect(provider.game.history.last.timeSpent, 5);

    provider.nextRound();
    // Continuation : exactement les 25 s reportées, aperçu et chrono d'accord.
    expect(provider.turnTime.total, 25);
    provider.startTurn();
    expect(provider.game.timeRemaining, 25);
    provider.startTurnTimer();
    expect(allotted(provider), 25);
    expect(provider.game.turnAllottedSeconds, 25);

    provider.passWord(); // 25 → 20
    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);
    final continuation = provider.game.history.last;
    expect(continuation.isBonusContinuation, isTrue);
    // Bug reproduit : 30 − 20 = 10 avant, 25 − 20 = 5 maintenant.
    expect(continuation.timeSpent, 5);

    // L'équipe suivante repart de la base.
    expect(provider.turnTime.total, 30);
  });

  test(
      'Fiesta : rattrapage calculé en fin de manche, consommé au premier tour '
      'non-continuation, jamais sur la continuation ; malus de 10 s ; même '
      'temps après un kill et après un retour arrière', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        catchUp: CatchUpRules.auto,
        modifiers: const {
          'minus_10s': ModifierSetting(
            active: true,
            arrival: ModifierArrival.fixed,
            startRound: 1,
            fixedRound: 2,
            charges: 1,
          ),
        },
      ),
    );
    expect(provider.turnTime.total, 30);
    final leader = provider.getCurrentTeam()!.id;
    final trailing = provider.teams.singleWhere((t) => t.id != leader).id;

    finishRoundWithCarryOver(provider); // leader 2 – trailing 0
    Map<String, int> preview() =>
        {for (final e in provider.catchUpPreview) e.teamId: e.seconds};
    expect(preview(), {leader: -2, trailing: 6});

    // Retour arrière depuis la transition, puis revalidation : identique.
    provider.restorePreValidationState();
    expect(provider.catchUpPreview, isEmpty);
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(preview(), {leader: -2, trailing: 6});

    provider.nextRound();
    expect(provider.game.fiesta!.catchUpDue, {leader: -2, trailing: 6});
    expect(
        provider.currentTeamModifiers.map((m) => m.catalogId), ['minus_10s']);

    // Continuation du leader : 25 s reportées, ni malus du leader ni −10 s,
    // et son dû n'est pas consommé.
    expect(provider.turnTime.total, 25);
    provider.startTurn();
    provider.startTurnTimer();
    expect(allotted(provider), 25);
    expect(provider.game.fiesta!.catchUpDue, {leader: -2, trailing: 6});
    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);

    // Premier tour non-continuation de la menée : 30 + 6 − 10.
    expect(provider.getCurrentTeam()!.id, trailing);
    expect(provider.turnTime.total, 26);
    expect(provider.turnTime.lines.map((l) => l.seconds), [30, 6, -10]);
    provider.startTurn();
    expect(provider.game.timeRemaining, 26);
    provider.startTurnTimer();
    expect(allotted(provider), 26);
    expect(provider.game.turnAllottedSeconds, 26);
    expect(provider.game.fiesta!.catchUpDue, {leader: -2});

    // App tuée en plein tour : reste gelé et durée allouée retrouvés.
    provider.pauseTurn();
    final frozen = provider.turnClock.frozenRemainingMs;
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.turnClock.frozenRemainingMs, frozen);
    expect(reloaded.game.turnAllottedSeconds, 26);
    expect(reloaded.game.fiesta!.catchUpDue, {leader: -2});
    reloaded.resumeTurn();
    reloaded.endTurn();
    reloaded.savePreValidationState(const []);
    reloaded.validateWords(const []);
    expect(
        reloaded.game.history.last.timeSpent, 26 - reloaded.game.timeRemaining);

    // Leader, premier tour non-continuation : 30 − 2 − 10.
    expect(reloaded.getCurrentTeam()!.id, leader);
    expect(reloaded.turnTime.total, 18);

    // Retour arrière depuis cet avant-tour : le tour de la menée a eu lieu,
    // son rattrapage reste consommé après revalidation.
    reloaded.restorePreValidationState();
    reloaded.savePreValidationState(const []);
    reloaded.validateWords(const []);
    expect(reloaded.game.fiesta!.catchUpDue, {leader: -2});
    expect(reloaded.turnTime.total, 18);

    playEmptyTurn(reloaded);
    expect(reloaded.game.fiesta!.catchUpDue, isEmpty);
    // Les tours suivants de la manche : base − 10 s seulement.
    expect(reloaded.turnTime.total, 20);
  });
}
