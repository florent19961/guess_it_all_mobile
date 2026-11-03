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

void main() {
  test(
      '« Rejouer » remet la config Fiesta gelée en attente et passe par le '
      'Récap ; après une partie Classique, rien en attente', () async {
    final provider = await givenReadyProvider();
    provider.setPendingFiesta(
      FiestaRules(mode: FiestaMode.auto, symmetric: false),
    );
    await provider.startGame(fiesta: provider.pendingFiesta);

    await provider.restartWithSamePlayers();

    expect(provider.game.currentScreen, AppConstants.screenFiestaRecap);
    expect(provider.pendingFiesta!.mode, FiestaMode.auto);
    expect(provider.pendingFiesta!.symmetric, isFalse);

    // Partie Classique lancée alors qu'une config traîne en attente : Rejouer
    // suit la partie jouée, pas l'attente.
    await provider.startGame();

    await provider.restartWithSamePlayers();

    expect(provider.game.currentScreen, AppConstants.screenSettings);
    expect(provider.pendingFiesta, isNull);
  });
}
