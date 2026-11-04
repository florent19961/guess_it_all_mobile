import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';

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
  group('Gel de la configuration Fiesta au lancement', () {
    test(
        'startGame(fiesta:) gèle une copie : modifier la source ensuite '
        'ne change pas la partie', () async {
      final provider = await givenReadyProvider();
      final sourceModifiers = <String, ModifierSetting>{
        'no_pass': const ModifierSetting(
          active: true,
          arrival: ModifierArrival.draw,
          startRound: 1,
          charges: 0,
        ),
      };
      final rules =
          FiestaRules(mode: FiestaMode.custom, modifiers: sourceModifiers);

      await provider.startGame(fiesta: rules);
      sourceModifiers['draw'] = const ModifierSetting(
        active: true,
        arrival: ModifierArrival.fixed,
        startRound: 3,
        charges: 0,
      );

      expect(provider.isFiesta, isTrue);
      expect(provider.game.fiesta!.rules.modifiers.keys, ['no_pass']);
      // Tirage de M1 (2-5) : pris dans la config gelée, seul `no_pass` y est.
      expect(provider.game.fiesta!.active.map((m) => m.catalogId), ['no_pass']);
    });

    test(
        '« Une seule réponse » : tirée par partie en Auto (graine du gameId), '
        'reprise telle quelle de l\'ensemble en Personnalisé', () async {
      final provider = await givenReadyProvider();
      final outcomes = <bool>{};
      for (var i = 0; i < 40; i++) {
        await provider.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
        final oneAnswer = provider.game.fiesta!.rules.oneAnswer;
        expect(oneAnswer, drawsOneAnswer(provider.game.gameId!));
        outcomes.add(oneAnswer);
      }
      expect(outcomes, {true, false});

      for (final chosen in [true, false]) {
        await provider.startGame(
            fiesta: FiestaRules(mode: FiestaMode.custom, oneAnswer: chosen));
        expect(provider.game.fiesta!.rules.oneAnswer, chosen);
      }
    });

    test('startGame() sans argument efface la Fiesta de la partie précédente',
        () async {
      final provider = await givenReadyProvider();
      await provider.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
      expect(provider.isFiesta, isTrue);

      await provider.startGame();

      expect(provider.isFiesta, isFalse);
      expect(provider.game.toJson().containsKey('fiesta'), isFalse);
    });

    test('le retour arrière restaure l\'état Fiesta capturé', () async {
      final provider = await givenReadyProvider();
      await provider.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
      provider.startTurn();
      provider.startTurnTimer();
      provider.endTurn();
      final captured = provider.game.fiesta!.toJson();

      provider.savePreValidationState(const []);
      // Aucune API publique ne mute encore `fiesta` après le snapshot : on
      // relance en Classique, ce qui l'efface sans toucher au snapshot.
      await provider.startGame();
      expect(provider.game.fiesta, isNull);

      provider.restorePreValidationState();

      expect(provider.game.fiesta, isNotNull);
      expect(provider.game.fiesta!.toJson(), equals(captured));
    });
  });
}
