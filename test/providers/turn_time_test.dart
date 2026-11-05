import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/word_event.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

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

    test('un aller-retour pause/reprise ne RESTITUE pas de temps au joueur',
        () async {
      // 🔴 Ce test existe parce que le précédent ne prouvait rien : il ne
      // comparait que la seconde AFFICHÉE, donc 30 contre 30, alors que le
      // reste réel passait de 29 001 ms à 30 000 ms. Le tour s'allongeait de
      // près d'une seconde à chaque ouverture de dialogue, indéfiniment.
      final provider = await givenProvider();
      provider.startTurnTimer();

      // On se place volontairement sur un reste NON rond : c'est le seul cas
      // où l'arrondi de persistance se voit.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      provider.pauseTurn();
      final resteAuGel = provider.turnClock.frozenRemainingMs!;
      expect(resteAuGel % 1000, isNot(0),
          reason: 'sans reste fractionnaire, le test ne prouverait rien');

      provider.resumeTurn();
      final apres = provider.turnClock
          .remainingMsAt(DateTime.now().millisecondsSinceEpoch);

      // Tolérance d'exécution seulement : le temps réel s'écoule entre les deux
      // mesures, donc `apres` doit être <= au gel, jamais au-dessus.
      expect(apres, lessThanOrEqualTo(resteAuGel),
          reason: 'reprendre ne doit JAMAIS rendre plus que ce qui a été gelé');
      expect(apres, greaterThan(resteAuGel - 200),
          reason: 'et ne doit pas non plus en perdre');
    });

    test(
        'suspendre puis reprendre par l\'accueil ne rend pas de temps non plus',
        () async {
      // Même défaut, autre chemin : `suspendGame`/`resumeGame` écrivaient les
      // champs à la main au lieu de passer par l'horloge.
      final provider = await givenProvider();
      provider.startTurnTimer();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      provider.pauseTurn();
      final resteAuGel = provider.turnClock.frozenRemainingMs!;
      expect(resteAuGel % 1000, isNot(0));

      await provider.suspendGame();
      expect(provider.turnClock.frozenRemainingMs, resteAuGel,
          reason: 'suspendre ne doit rien arrondir');

      provider.resumeGame();
      final apres = provider.turnClock
          .remainingMsAt(DateTime.now().millisecondsSinceEpoch);
      expect(apres, lessThanOrEqualTo(resteAuGel));
      expect(apres, greaterThan(resteAuGel - 200));
    });

    test('une partie gelée par une version ANTÉRIEURE reste lisible', () async {
      // L'app est publiée : un joueur peut avoir une partie en pause écrite par
      // la version en store, qui n'a que le champ en secondes. On la relit —
      // au pire elle rend l'arrondi historique, on ne la casse pas.
      final provider = await givenProvider();
      provider.startTurnTimer();
      provider.pauseTurn();

      provider.game.pausedRemainingMs = null; // format d'avant
      expect(provider.turnClock.isPaused, isTrue);
      expect(provider.turnClock.frozenRemainingMs,
          provider.game.pausedTimeRemaining! * 1000);
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
    // Revue de la PR #41 : le chrono et la confirmation « Terminer » peuvent
    // se croiser. Le second appel ajoutait un `expired` pour le même mot, et
    // remettait à zéro le temps reporté d'une manche finie en avance.
    Future<GameProvider> givenGameTurn() async {
      await givenPrefs();
      givenFakePlatformPlugins();
      final provider = GameProvider();
      await pumpEventQueue();
      for (final name in ['A', 'B', 'C', 'D']) {
        final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
        provider.updatePlayerWords(id, ['$name-1', '$name-2']);
      }
      provider.createTeams();
      provider.randomizeTeams();
      await provider.startGame();
      provider.startTurn();
      provider.startTurnTimer();
      return provider;
    }

    test('un second endTurn ne change ni l\'état ni les événements', () async {
      final provider = await givenGameTurn();
      final word = provider.game.currentWord!;

      provider.endTurn();
      expect(provider.game.currentScreen, AppConstants.screenVerification);
      final state = jsonEncode(provider.game.toJson());
      final events = List.of(AnalyticsService().currentGame!.events);

      provider.endTurn();

      expect(jsonEncode(provider.game.toJson()), state);
      expect(AnalyticsService().currentGame!.events, events);
      expect(
        events.where(
            (e) => e.word == word && e.eventType == WordEventType.expired),
        hasLength(1),
      );
    });

    test('endTurn après une manche finie en avance garde le temps reporté',
        () async {
      final provider = await givenGameTurn();
      while (provider.game.remainingWords.isNotEmpty) {
        provider.markWordAsGuessed();
      }
      final carried = provider.game.turnBonusTime;
      expect(carried, greaterThan(0));

      provider.endTurn();

      expect(provider.game.turnBonusTime, carried);
    });

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
