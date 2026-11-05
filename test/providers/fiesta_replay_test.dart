import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
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
    provider.addPlayer(name);
  }
  givenWords(provider);
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// « Rejouer » efface les mots : on les ressaisit avant chaque lancement.
void givenWords(GameProvider provider) {
  for (final player in provider.players) {
    provider.updatePlayerWords(player.id, ['mot-${player.name}']);
  }
}

void main() {
  test(
      '« Rejouer » remet la config Fiesta gelée en attente et revient aux '
      'Paramètres ; après une partie Classique, rien en attente', () async {
    final provider = await givenReadyProvider();
    provider.setPendingFiesta(classicEnsemble.rules);
    await provider.startGame(fiesta: provider.pendingFiesta);

    await provider.restartWithSamePlayers();

    expect(provider.game.currentScreen, AppConstants.screenSettings);
    expect(provider.pendingFiesta!.ensembleName, 'Fiesta classique');

    // Même chose via l'accueil : fin de partie, puis « Rejouer » de l'accueil.
    givenWords(provider);
    await provider.startGame(fiesta: provider.pendingFiesta);
    await provider.endGameAndGoHome();
    await provider.restartWithSamePlayers();

    expect(provider.game.currentScreen, AppConstants.screenSettings);
    expect(provider.pendingFiesta!.ensembleName, 'Fiesta classique');

    // App tuée en pleine partie Fiesta : la relance remet la config en attente,
    // sinon « Retour aux équipes » puis « Lancer » repartirait en Classique.
    givenWords(provider);
    await provider.startGame(fiesta: classicEnsemble.rules);
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.isFiesta, isTrue);
    expect(reloaded.pendingFiesta?.ensembleName, 'Fiesta classique');

    // « Nouvelle partie » retrouve le dernier choix, sans les règles gelées.
    await reloaded.startNewGame();
    expect(reloaded.pendingFiesta!.toJson(), classicEnsemble.rules.toJson());

    // Partie Classique lancée alors qu'une config traîne en attente : Rejouer
    // suit la partie jouée, pas l'attente.
    givenWords(provider);
    await provider.startGame();

    await provider.restartWithSamePlayers();

    expect(provider.game.currentScreen, AppConstants.screenSettings);
    expect(provider.pendingFiesta, isNull);
  });
}
