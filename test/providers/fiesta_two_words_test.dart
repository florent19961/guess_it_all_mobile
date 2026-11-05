import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/word_event.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// 4 joueurs × 3 mots, 2 équipes, pénalité de passe 0 (les passes ne vident
/// pas le chrono).
Future<GameProvider> givenReadyProvider() async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in ['A', 'B', 'C', 'D']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['$name-1', '$name-2', '$name-3']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  provider.updateSettings(passPenalty: 0);
  return provider;
}

/// Personnalisé, sans tirage : [ids] en cartouche, 1 par équipe pour la partie
/// (à allumer avant le tour).
FiestaRules fixedOnRound1(List<String> ids) => FiestaRules(
      drawCount: 0,
      modifiers: {
        for (final id in ids) id: ModifierSetting(charges: 1),
      },
    );

Future<GameProvider> givenTwoWordsTurn({bool alsoDouble = false}) async {
  final provider = await givenReadyProvider();
  await provider.startGame(
      fiesta: fixedOnRound1(['two_words', if (alsoDouble) 'double_points']));
  provider.setTwoWords(true);
  if (alsoDouble) provider.setDoublePoints(true);
  provider.startTurn();
  provider.startTurnTimer();
  return provider;
}

/// Pool jamais corrompu : cartes distinctes et dans le pool, pas de doublon,
/// aucun mot perdu ni trouvé encore à faire deviner.
void expectPoolIntact(GameProvider p) {
  final g = p.game;
  final pool = g.remainingWords;
  expect(pool.toSet().length, pool.length, reason: 'doublon dans le pool');
  expect({
    ...pool,
    ...g.wordsGuessedThisTurn,
    ...g.passedWordsThisTurn
  }, g.allWords.toSet(), reason: 'mot perdu');
  expect(pool.toSet().intersection(g.wordsGuessedThisTurn.toSet()), isEmpty);
  if (g.currentWord != null) expect(pool, contains(g.currentWord));
  if (p.secondWord != null) {
    expect(pool, contains(p.secondWord));
    expect(p.secondWord, isNot(g.currentWord));
  }
}

void main() {
  test(
      'Deux cartes : seule la carte visée est remplacée, par un mot ≠ l\'autre ; '
      'pool intact ; une seule carte au dernier mot, qui revient si on la passe ; '
      'puis fin de manche avec temps reporté (AC2, AC3, AC8)', () async {
    final p = await givenTwoWordsTurn();
    expect(p.twoWordsLeft, 0);
    expect(p.secondWord, isNotNull);
    expectPoolIntact(p);

    // Alterner carte A / carte B, passer et trouver : recyclage compris.
    for (var i = 0; i < 8; i++) {
      final a = p.game.currentWord!;
      final b = p.secondWord!;
      final onA = i.isEven;
      final target = onA ? a : b;
      if (i % 4 < 2) {
        p.passWord(target);
        expect(p.game.passedWordsThisTurn, contains(target));
      } else {
        p.markWordAsGuessed(target);
        expect(p.game.wordsGuessedThisTurn, contains(target));
        expect(p.game.remainingWords, isNot(contains(target)));
      }
      // L'autre carte ne bouge pas.
      expect(onA ? p.secondWord : p.game.currentWord, onA ? b : a);
      expectPoolIntact(p);
    }

    // Un tap périmé (mot plus à l'écran) ne fait rien.
    final before = p.game.wordsGuessedThisTurn.length;
    p.markWordAsGuessed(p.game.wordsGuessedThisTurn.first);
    expect(p.game.wordsGuessedThisTurn.length, before);

    // Trouver la carte A jusqu'à ce qu'il ne reste qu'une carte.
    while (p.secondWord != null) {
      final b = p.secondWord!;
      p.markWordAsGuessed(p.game.currentWord!);
      expectPoolIntact(p);
      if (p.secondWord == null) expect(p.game.currentWord, b);
    }
    final last = p.game.currentWord!;
    expect(p.game.remainingWords, [last]);
    expect(p.effectiveRemainingWordsCount, 0);

    // Passer le dernier mot : il revient.
    p.passWord(last);
    expect(p.game.currentWord, last);
    expect(p.secondWord, isNull);

    p.markWordAsGuessed(last);
    expect(p.game.currentScreen, AppConstants.screenVerification);
    expect(p.game.remainingWords, isEmpty);
    expect(p.game.wordsGuessedThisTurn.toSet(), p.game.allWords.toSet());
    expect(p.game.turnBonusTime, isNotNull);
  });

  test(
      'Chrono à 0 avec deux cartes, ×2 : kill en plein tour = mêmes cartes ; '
      'vérification séparée de A et B ; retour arrière restaure les deux '
      '(AC4, AC5, AC6)', () async {
    var p = await givenTwoWordsTurn(alsoDouble: true);
    final teamId = p.getCurrentTeam()!.id;
    final a = p.game.currentWord!;
    final b = p.secondWord!;

    // AC5 : app tuée en plein tour.
    await pumpEventQueue();
    p = GameProvider();
    await pumpEventQueue();
    expect(p.game.currentWord, a);
    expect(p.secondWord, b);
    expect(p.isTwoWordsOn, isTrue);

    p.endTurn();
    expect(p.game.expiredWord, a);
    expect(p.secondExpiredWord, b);
    expect(p.secondWord, isNull);

    // AC4 : A validé, B refusé → 1 mot ×2, B retourne au pool.
    p.savePreValidationState([a]);
    p.validateWords([a]);
    expect(p.teams.firstWhere((t) => t.id == teamId).score, 2);
    expect(p.game.remainingWords, contains(b));
    expect(p.game.remainingWords, isNot(contains(a)));
    expect(p.secondExpiredWord, isNull);

    // AC6 : retour arrière.
    p.restorePreValidationState();
    expect(p.game.expiredWord, a);
    expect(p.secondExpiredWord, b);
    expect(p.game.restoredValidatedWords, [a]);
    expect(p.teams.firstWhere((t) => t.id == teamId).score, 0);

    p.savePreValidationState([a, b]);
    p.validateWords([a, b]);
    expect(p.teams.firstWhere((t) => t.id == teamId).score, 4);
    expect(p.game.remainingWords, isNot(contains(b)));
  });

  test(
      'Fin de manche à la vérification avec deux cartes expirées, puis '
      'continuation (même tour) : B dépouillée une seule fois, deux cartes '
      'tirées sans redépenser de charge (AC8)', () async {
    final p = await givenTwoWordsTurn();
    final teamId = p.getCurrentTeam()!.id;
    while (p.game.remainingWords.length > 2) {
      p.markWordAsGuessed(p.game.currentWord!);
    }
    p.endTurn();
    final validated = [
      ...p.game.wordsGuessedThisTurn,
      p.game.expiredWord!,
      p.secondExpiredWord!,
    ];
    p.validateWords(validated);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.secondExpiredWord, isNull);

    p.nextRound();
    expect(p.getCurrentTeam()!.id, teamId);
    p.startTurn();
    p.startTurnTimer();
    expect(p.isTwoWordsOn, isTrue);
    expect(p.secondWord, isNotNull);
    expectPoolIntact(p);
    expect(p.game.fiesta!.chargesUsed.where((u) => u.catalogId == 'two_words'),
        hasLength(1));
  });

  test(
      'Fiesta v2 : plus de plafond, les deux bonus s\'allument ensemble ; '
      'une incompatibilité avec une règle de manche refuse (sans dépenser)',
      () async {
    final p = await givenReadyProvider();
    await p.startGame(
      fiesta: FiestaRules(
        drawCount: 0,
        modifiers: {
          'no_pass': const ModifierSetting(always: true),
          'reversed': const ModifierSetting(always: true),
          for (final id in ['two_words', 'double_points'])
            id: ModifierSetting(charges: 1),
        },
      ),
    );
    expect(p.turnModifiers.map((m) => m.catalogId), ['no_pass', 'reversed']);

    // « Interdit de passer » en jeu : « Deux mots » est refusé.
    expect(p.twoWordsBlocked, isTrue);
    p.setTwoWords(true);
    expect(p.isTwoWordsArmed, isFalse);
    expect(p.twoWordsLeft, 0, reason: 'verrouillée par le Toujours');
    // ×2 s'allume malgré 2 modificateurs déjà en jeu.
    p.setDoublePoints(true);
    expect(p.isDoublePointsArmed, isTrue);
  });

  test(
      'Analytics après un kill (vrai redémarrage du service) : en plein tour '
      'à deux cartes, puis sur la vérification, chaque événement terminal est '
      'écrit, sans durée inventée, avec manche, équipe et tags de la partie',
      () async {
    final p = await givenTwoWordsTurn(alsoDouble: true);
    final team = p.getCurrentTeam()!.id;
    final a = p.game.currentWord!;
    final b = p.secondWord!;

    Future<GameProvider> kill() async {
      await AnalyticsService().saveCurrentGame(); // app mise en arrière-plan
      AnalyticsService().forgetCurrentGame();
      final reloaded = GameProvider();
      await pumpEventQueue();
      return reloaded;
    }

    List<WordEvent> after(int n) =>
        AnalyticsService().currentGame!.events.skip(n).toList();
    void expectContext(List<WordEvent> events) {
      for (final e in events) {
        expect((e.round, e.turn, e.teamId), (1, 1, team), reason: '$e');
        expect(e.modifiers, ['double_points', 'two_words'], reason: '$e');
      }
    }

    // En plein tour : les deux cartes à l'écran avant le kill.
    var r = await kill();
    var seen = AnalyticsService().currentGame!.events.length;
    r.markWordAsGuessed(a);
    r.passWord(b);
    final a2 = r.game.currentWord!;
    final b2 = r.secondWord!;
    var events = after(seen);
    expect(
        events
            .where((e) => e.word == a || e.word == b)
            .map((e) => (e.word, e.eventType, e.durationMs)),
        [(a, WordEventType.guessed, null), (b, WordEventType.passed, null)]);
    expectContext(events);
    r.endTurn();

    // Sur la vérification : seul A' (expiré) est validé, a posteriori ; le
    // reste du tour (A trouvé, B passé, B' expiré) est invalidé.
    r = await kill();
    expect(r.game.currentScreen, AppConstants.screenVerification);
    seen = AnalyticsService().currentGame!.events.length;
    r.savePreValidationState([a2]);
    r.validateWords([a2]);
    events = after(seen);
    expect(
        events.map((e) => (e.word, e.eventType)),
        unorderedEquals([
          (a, WordEventType.invalidated),
          (b, WordEventType.invalidated),
          (b2, WordEventType.invalidated),
          (a2, WordEventType.guessed),
        ]));
    expectContext(events);
  });

  test(
      'Analytics : chaque carte a son shown puis son guessed / passed / '
      'expired avec durée, tag two_words (AC7) ; Classique : un mot, pas de tag',
      () async {
    final p = await givenTwoWordsTurn();
    final a = p.game.currentWord!;
    final b = p.secondWord!;
    p.markWordAsGuessed(a); // carte A alors que B est le dernier `shown`
    final a2 = p.game.currentWord!;
    p.passWord(b);
    final b2 = p.secondWord!;
    p.endTurn();

    final events = AnalyticsService().currentGame!.events;
    void expectPair(String word, WordEventType end) {
      final mine = events.where((e) => e.word == word).toList();
      expect(mine.map((e) => e.eventType), [WordEventType.shown, end],
          reason: word);
      expect(mine.last.durationMs, isNotNull, reason: word);
      expect(mine.first.modifiers, contains('two_words'));
    }

    expectPair(a, WordEventType.guessed);
    expectPair(b, WordEventType.passed);
    expectPair(a2, WordEventType.expired);
    expectPair(b2, WordEventType.expired);

    // Classique : l'interrupteur ne fait rien, un mot à la fois, sans tag.
    final c = await givenReadyProvider();
    await c.startGame();
    c.setTwoWords(true);
    c.startTurn();
    c.startTurnTimer();
    expect(c.secondWord, isNull);
    final w = c.game.currentWord!;
    c.markWordAsGuessed();
    final classic = AnalyticsService().currentGame!.events;
    expect(classic.map((e) => (e.word, e.eventType)).take(3), [
      (w, WordEventType.shown),
      (w, WordEventType.guessed),
      (c.game.currentWord!, WordEventType.shown),
    ]);
    expect(classic.every((e) => e.modifiers == null), isTrue);
    expect(classic[1].durationMs, isNotNull);
    expect(c.game.toJson().containsKey('fiesta'), isFalse);
  });
}
