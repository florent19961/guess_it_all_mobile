import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Un provider prêt à lancer une partie : 2 joueurs, 2 équipes, 1 mot chacun.
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

/// Un seul tour fait deviner les 2 mots, puis passe par la vérification :
/// fin de la manche, écran de transition.
void playWholeRound(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.markWordAsGuessed();
  provider.markWordAsGuessed();
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
}

List<String> ids(Iterable<dynamic> mods) =>
    mods.map((m) => '${m.catalogId}@${m.round}').toList();

void main() {
  test(
      'Fiesta Auto : le tirage de M2 est visible dès la transition, identique '
      'après un retour arrière et après une app tuée, puis actif au '
      '« Manche suivante » à la place de celui de M1', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
    expect(provider.game.fiesta!.active, isNotEmpty);
    expect(provider.game.fiesta!.active.every((m) => m.round == 1), isTrue);

    playWholeRound(provider);
    expect(provider.game.currentScreen, AppConstants.screenTransition);
    final preview = ids(provider.nextRoundModifiers);
    expect(preview, isNotEmpty);

    // Retour arrière depuis la transition, puis revalidation : pas de relance.
    provider.restorePreValidationState();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(ids(provider.nextRoundModifiers), preview);

    // App tuée sur la transition : même tirage à la réouverture.
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.game.currentScreen, AppConstants.screenTransition);
    expect(ids(reloaded.nextRoundModifiers), preview);
    expect(
        ids(reloaded.game.fiesta!.active), ids(provider.game.fiesta!.active));

    reloaded.nextRound();
    expect(ids(reloaded.game.fiesta!.active), preview);
    expect(ids(reloaded.currentTeamModifiers), preview);
  });

  test('Classique : ni fiesta, ni tirage, ni badge, à aucune étape', () async {
    final provider = await givenReadyProvider();
    await provider.startGame();
    playWholeRound(provider);
    expect(provider.nextRoundModifiers, isEmpty);
    provider.nextRound();
    expect(provider.game.fiesta, isNull);
    expect(provider.currentTeamModifiers, isEmpty);
    expect(provider.malusToReveal, isEmpty);
  });
}
