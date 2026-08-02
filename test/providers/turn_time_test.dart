import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';

import '../helpers/test_prefs.dart';

/// Laisse le `_loadFromStorage()` lancé par le constructeur se terminer.
Future<GameProvider> givenProvider() async {
  await givenPrefs();
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

void main() {
  group('Temps du tour — le gel purge la deadline', () {
    test('mettre en pause RETIRE la deadline et fige le reste', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();

      expect(provider.game.turnEndTimestamp, isNotNull);
      expect(provider.turnClock.isRunning, isTrue);

      provider.pauseTurn();

      // C'est LE cœur du correctif : sans purge de la deadline, elle continue de
      // courir pendant que l'affichage est figé.
      expect(provider.game.turnEndTimestamp, isNull,
          reason: 'la deadline doit être retirée, pas seulement ignorée');
      expect(provider.game.pausedTimeRemaining, isNotNull);
      expect(provider.turnClock.isPaused, isTrue);
    });

    test(
        'le temps passé en pause n\'est PAS décompté, quelle qu\'en soit la durée',
        () async {
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();

      final figeAuGel = provider.game.pausedTimeRemaining;

      // Le joueur laisse le dialogue ouvert (ou prend un appel).
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Assertion EXACTE et non tolérancée : une horloge gelée ne dépend pas de
      // `now`, donc le reste doit être rigoureusement identique. Avant le
      // correctif, `suspendGame` recalculait depuis la deadline vivante et ces
      // 600 ms étaient volées au joueur.
      expect(provider.game.pausedTimeRemaining, figeAuGel);

      await provider.suspendGame();
      expect(provider.game.pausedTimeRemaining, figeAuGel,
          reason: 'suspendre après un gel ne doit rien recalculer');
    });

    test('reprendre restitue le temps gelé', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();

      final figeAuGel = provider.game.pausedTimeRemaining!;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      provider.resumeTurn();

      expect(provider.game.turnEndTimestamp, isNotNull);
      expect(provider.game.pausedTimeRemaining, isNull,
          reason:
              'le reste gelé est consommé : garder les deux serait incohérent');

      final now = DateTime.now().millisecondsSinceEpoch;
      expect(provider.turnClock.displayedSecondsAt(now), figeAuGel);
    });

    test('pauseTurn et resumeTurn sont idempotents', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();

      provider.pauseTurn();
      final premierGel = provider.game.pausedTimeRemaining;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      provider
          .pauseTurn(); // 2e appel (ex. : dialogue + passage en arrière-plan)

      expect(provider.game.pausedTimeRemaining, premierGel,
          reason: 'un 2e gel ne doit pas re-geler sur une valeur déjà gelée');

      provider.resumeTurn();
      final deadline = provider.game.turnEndTimestamp;
      provider.resumeTurn(); // no-op attendu
      expect(provider.game.turnEndTimestamp, deadline);
    });
  });

  group('Temps du tour — fin de tour', () {
    test(
        'terminer un tour GELÉ utilise le reste gelé, pas une deadline périmée',
        () async {
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();

      final figeAuGel = provider.game.pausedTimeRemaining!;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      provider.endTurn();

      expect(provider.game.timeRemaining, figeAuGel);
    });

    test('endTurn ARRÊTE l\'horloge : ni deadline, ni gel résiduel', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();
      provider.endTurn();

      expect(provider.game.turnEndTimestamp, isNull);
      expect(provider.game.pausedTimeRemaining, isNull);
      expect(provider.turnClock.isStopped, isTrue);

      // Conséquence directe : le `then` du dialogue « Terminer le tour » appelle
      // resumeTurn(), qui ne doit PAS ré-armer une deadline sur l'écran de
      // vérification.
      provider.resumeTurn();
      expect(provider.game.turnEndTimestamp, isNull);
    });
  });

  group('Temps du tour — pénalité de passe', () {
    test('refreshDisplayedTime ne notifie que si la seconde change', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();

      var notifications = 0;
      provider.addListener(() => notifications++);

      // Plusieurs ticks dans la même seconde.
      for (var i = 0; i < 5; i++) {
        provider.refreshDisplayedTime();
      }

      expect(notifications, 0,
          reason: 'l\'ancien code notifiait à chaque tick, soit 10 fois par '
              'seconde, ce qui reconstruisait tout l\'arbre sous le Consumer racine');
    });

    test('refreshDisplayedTime ne fait rien sur une horloge gelée', () async {
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();
      final fige = provider.game.timeRemaining;

      await Future<void>.delayed(const Duration(milliseconds: 400));
      provider.refreshDisplayedTime();

      expect(provider.game.timeRemaining, fige);
    });
  });
}
