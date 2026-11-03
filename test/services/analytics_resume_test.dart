import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/word_stats.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';

import '../helpers/test_prefs.dart';

Future<void> demarrerPartie(AnalyticsService a, String id) => a.startGame(
      gameId: id,
      numberOfPlayers: 4,
      numberOfTeams: 2,
      totalWords: 2,
      turnDuration: 30,
      selectedCategories: const ['nature'],
      selectedDifficultyLevels: const [1, 2],
      wordMetadata: const {
        'chat': WordMetadata(
            word: 'chat', categoryId: 'nature', difficulty: 1, language: 'fr'),
        'chien': WordMetadata(
            word: 'chien', categoryId: 'nature', difficulty: 1, language: 'fr'),
      },
    );

void main() {
  late AnalyticsService analytics;

  setUp(() async {
    await givenPrefs();
    givenFakePlatformPlugins();
    analytics = AnalyticsService();
    // Les deux services sont des SINGLETONS : sans remise à zéro explicite, le
    // compteur d'un test fuiterait dans le suivant.
    analytics.forgetCurrentGame();
    await WordHistoryService().initialize();
    await WordHistoryService().clearHistory();
  });

  test('une partie tuée puis rouverte reprend son tracking', () async {
    await demarrerPartie(analytics, 'g1');
    await analytics.saveCurrentGame();

    // Simule le kill : l'instance perd `_currentGame`, le disque le garde.
    analytics.forgetCurrentGame();
    expect(analytics.isTracking, isFalse);

    expect(await analytics.resumeGame('g1'), isTrue);
    expect(analytics.isTracking, isTrue);
    expect(analytics.currentGame!.gameId, 'g1');
  });

  test('reprendre incrémente bien l\'historique des mots à la fin', () async {
    // 🔴 C'est l'impact JEU du défaut : sans reprise, `endGame()` sortait en
    // early-return et `incrementWords` n'était jamais appelé — la priorisation
    // « mots jamais vus » ne s'appliquait plus, donc les mêmes mots
    // ressortaient à la partie suivante.
    final history = WordHistoryService();
    await history.initialize();

    await demarrerPartie(analytics, 'g2');
    await analytics.saveCurrentGame();
    analytics.forgetCurrentGame();

    await analytics.resumeGame('g2');
    await analytics.endGame();

    expect(history.getSeenCount('chat'), 1);
    expect(history.getSeenCount('chien'), 1);
  });

  test('sans reprise, l\'historique reste à zéro', () async {
    // Le témoin négatif : c'est exactement l'état d'avant le correctif.
    final history = WordHistoryService();
    await history.initialize();

    await demarrerPartie(analytics, 'g3');
    await analytics.saveCurrentGame();
    analytics.forgetCurrentGame();

    await analytics.endGame(); // early-return : rien ne se passe

    expect(history.getSeenCount('chat'), 0);
  });

  test('une partie DÉJÀ terminée ne se reprend pas', () async {
    // Sinon on rejouerait son `endGame()`, donc un second `incrementWords` sur
    // les mêmes mots : le compteur de vus doublerait.
    final history = WordHistoryService();
    await history.initialize();

    await demarrerPartie(analytics, 'g4');
    await analytics.endGame();
    expect(history.getSeenCount('chat'), 1);

    expect(await analytics.resumeGame('g4'), isFalse,
        reason: 'une partie clôturée n\'est pas reprenable');
    expect(history.getSeenCount('chat'), 1, reason: 'pas de double comptage');
  });

  test('reprendre une partie inconnue échoue sans lever', () async {
    expect(await analytics.resumeGame('jamais-vue'), isFalse);
    expect(analytics.isTracking, isFalse);
  });
}
