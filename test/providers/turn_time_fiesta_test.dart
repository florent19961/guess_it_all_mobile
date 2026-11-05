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
      'Fiesta : le +10 s et le −10 s se composent, l\'aperçu et le chrono '
      'd\'accord, plancher tenu ; une continuation garde ses secondes exactes, '
      'même au tour où une règle de N+1 s\'applique ; même temps après un kill',
      () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
      fiesta: FiestaRules(
        drawCount: 1,
        modifiers: {
          for (final id in ['plus_10s', 'minus_10s'])
            id: ModifierSetting(charges: 2),
          // Une règle de M2, sans effet sur le temps.
          'other_language': const ModifierSetting(draw: true),
        },
      ),
    );
    final first = provider.getCurrentTeam()!.id;
    final other = provider.teams.singleWhere((t) => t.id != first).id;
    expect(provider.turnTime.total, 30);

    // Allumé : l'aperçu l'annonce, éteint il repart, rien n'est dépensé.
    provider.toggleBonus('plus_10s');
    expect(provider.turnTime.total, 40);
    provider.toggleBonus('plus_10s');
    expect(provider.turnTime.total, 30);
    expect(provider.game.fiesta!.chargesUsed, isEmpty);
    provider.toggleBonus('plus_10s');
    expect(provider.inflictMalus('minus_10s', other), isNull);

    // Une passe (40 → 35) puis les 2 mots : 35 s reportées.
    provider.startTurn();
    expect(provider.game.timeRemaining, 40);
    provider.startTurnTimer();
    expect(allotted(provider), 40);
    expect(provider.game.turnAllottedSeconds, 40);
    expect(
        provider.game.fiesta!.chargesUsed
            .where((u) => u.catalogId == 'plus_10s'),
        hasLength(1));
    provider.passWord();
    provider.markWordAsGuessed();
    provider.markWordAsGuessed();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(provider.game.turnBonusTime, 35);
    provider.nextRound();

    // Continuation : le +10 s déjà dépensé n'ajoute rien, seules les secondes
    // reportées comptent ; la règle de M2 s'applique, elle.
    expect(provider.isContinuation, isTrue);
    expect(provider.currentTeamModifiers.map((m) => m.catalogId),
        contains('other_language'));
    expect(provider.turnTime.total, 35);
    provider.startTurn();
    provider.startTurnTimer();
    expect(allotted(provider), 35);
    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);

    // Le −10 s reçu tombe sur le premier tour de l'autre équipe : 30 − 10.
    expect(provider.getCurrentTeam()!.id, other);
    expect(provider.turnTime.total, 20);
    expect(provider.turnTime.lines.map((l) => l.seconds), [30, -10]);
    provider.startTurn();
    expect(provider.game.timeRemaining, 20);
    provider.startTurnTimer();
    expect(allotted(provider), 20);

    // App tuée en plein tour : reste gelé et durée allouée retrouvés.
    provider.pauseTurn();
    final frozen = provider.turnClock.frozenRemainingMs;
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.turnClock.frozenRemainingMs, frozen);
    expect(reloaded.game.turnAllottedSeconds, 20);
    reloaded.resumeTurn();
    reloaded.endTurn();
    reloaded.savePreValidationState(const []);
    reloaded.validateWords(const []);

    // Plus de −10 s : parti à la fin du tour visé. Le +10 s ne se rejoue pas
    // tout seul.
    expect(reloaded.getCurrentTeam()!.id, first);
    expect(reloaded.turnTime.total, 30);
    playEmptyTurn(reloaded);
    expect(reloaded.turnTime.total, 30);
  });
}
