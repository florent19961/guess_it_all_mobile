import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// [teams] équipes de 3 joueurs (2 mots chacun), ordre fixé : équipes puis
/// joueurs dans l'ordre.
Future<GameProvider> givenGame(int teams,
    {FiestaRules? fiesta, int wordsEach = 2}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final p = GameProvider();
  await pumpEventQueue();
  p.updateSettings(numberOfTeams: teams);
  final ids = <String>[];
  for (var i = 0; i < teams * 3; i++) {
    final id = (p.addPlayer('J$i')['player'] as dynamic).id as String;
    p.updatePlayerWords(id, [for (var w = 0; w < wordsEach; w++) 'm$i-$w']);
    ids.add(id);
  }
  p.createTeams();
  for (var i = 0; i < ids.length; i++) {
    p.movePlayerToTeam(ids[i], p.teams[i ~/ 3].id);
  }
  await p.startGame(fiesta: fiesta);
  final fixed = p.game.toJson()
    ..['teamPlayOrder'] = List<int>.generate(teams, (i) => i)
    ..['playerOrderByTeam'] = {
      for (final t in p.teams) t.id: [0, 1, 2],
    }
    ..['currentTeamIndex'] = 0
    ..['currentPlayerIndexInTeam'] = 0
    ..['currentTurnIndex'] = 0;
  p.goToScreen(AppConstants.screenVerification);
  p.savePreValidationState(const []);
  p.game.preValidationSnapshot!['game'] = fixed;
  p.restorePreValidationState();
  p.goToScreen(AppConstants.screenGame);
  return p;
}

FiestaRules stock(List<String> ids, {bool challenges = false}) => FiestaRules(
      challenges: challenges,
      modifiers: {for (final id in ids) id: const ModifierSetting(charges: 1)},
    );

void start(GameProvider p) {
  p.startTurn();
  p.startTurnTimer();
}

/// Le chrono tombe : deadline dépassée, comme le ticker la verrait.
void buzzer(GameProvider p) {
  p.game.turnEndTimestamp = DateTime.now().millisecondsSinceEpoch - 1;
}

void validate(GameProvider p, List<String> words) {
  p.savePreValidationState(words);
  p.validateWords(words);
}

/// Tour normal : [n] mots puis fin du tour, chrono non écoulé.
void playTurn(GameProvider p, int n) {
  start(p);
  for (var i = 0; i < n; i++) {
    p.markWordAsGuessed();
  }
  if (p.game.currentScreen != AppConstants.screenVerification) p.endTurn();
  validate(p, List<String>.from(p.game.wordsGuessedThisTurn));
}

/// Le tour en cours (déjà démarré) devine tout sauf le dernier mot, le chrono
/// tombe sur celui-ci, et il est validé : fin de manche à 0 s.
void finishAtBuzzer(GameProvider p) {
  while (p.game.remainingWords.length > 1) {
    p.markWordAsGuessed();
  }
  buzzer(p);
  p.endTurn();
  expect(p.game.timeRemaining, 0);
  validate(p, [...p.game.wordsGuessedThisTurn, p.game.expiredWord!]);
  expect(p.game.currentScreen, AppConstants.screenTransition);
}

void expectNormalTurnOf(GameProvider p, int teamIndex, int playerIndex) {
  expect(p.game.currentScreen, AppConstants.screenGame);
  expect(p.teams.indexOf(p.getCurrentTeam()!), teamIndex, reason: 'équipe');
  expect(p.game.currentPlayerIndexInTeam, playerIndex, reason: 'joueur');
  expect(p.isContinuation, isFalse);
  expect(p.game.turnBonusTime, isNull);
  expect(p.turnTime.total, p.settings.turnDuration);
}

int left(GameProvider p, String id) =>
    p.reserve.firstWhere((c) => c.catalogId == id).left;

void main() {
  for (final teams in [2, 3, 4]) {
    test('$teams équipes : pas de tour à 0 s, l\'équipe suivante commence M2',
        () async {
      final p = await givenGame(teams, wordsEach: 1);
      final total = p.game.allWords.length;

      // Équipe 0 trouve tout : le dernier mot, validé, sur le chrono.
      start(p);
      finishAtBuzzer(p);

      expect(p.getCurrentTeam(), isNotNull);
      expect(p.game.pendingBonusTurnId, isNull);
      expect(p.game.turnBonusTime, isNull);
      expect(p.teams[0].scoreByRound, [total, 0, 0],
          reason: 'le point du mot validé reste');
      p.nextRound();

      expectNormalTurnOf(p, 1, 0);

      // Puis la rotation complète, sans recul ni saut.
      for (final (team, player) in [
        for (var t = 2; t < teams; t++) (t, 0),
        (0, 1),
        (1, 1),
      ]) {
        playTurn(p, 0);
        expectNormalTurnOf(p, team, player);
      }
      // Tour suivant de l'équipe qui a fini à 0 : un tour plein et normal.
      expect(p.game.history.where((h) => h.isBonusContinuation), isEmpty);
    });
  }

  test('le tour qui suit n\'est pas une continuation, et ne fusionne rien',
      () async {
    final p = await givenGame(2, wordsEach: 1);
    start(p);
    finishAtBuzzer(p);
    final firstTurn = p.game.history.last.turn;
    p.nextRound();

    playTurn(p, 2);

    final entry = p.game.history.last;
    expect(entry.round, 2);
    expect(entry.isBonusContinuation, isFalse);
    expect(entry.teamId, p.teams[1].id);
    expect(entry.playerId, p.teams[1].playerIds[0]);
    expect(entry.turn, firstTurn + 1);
    expect(entry.timeSpent, 0);
    expect(p.teams[1].scoreByRound, [0, 2, 0]);
  });

  group('seuil du report', () {
    test('1 ms à l\'horloge reste 1 s reportée : une continuation', () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      p.game.turnEndTimestamp = DateTime.now().millisecondsSinceEpoch + 400;
      final team = p.getCurrentTeam()!.id;
      p.markWordAsGuessed();
      expect(p.game.currentScreen, AppConstants.screenVerification);
      validate(p, List<String>.from(p.game.wordsGuessedThisTurn));
      p.nextRound();

      expect(p.getCurrentTeam()!.id, team);
      expect(p.isContinuation, isTrue);
      expect(p.game.turnBonusTime, 1);
      expect(p.turnTime.total, 1);
    });

    test(
        'dernier mot touché quand la deadline est déjà passée : 0, pas de tour',
        () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      buzzer(p);
      p.markWordAsGuessed();
      validate(p, List<String>.from(p.game.wordsGuessedThisTurn));
      p.nextRound();

      expectNormalTurnOf(p, 1, 0);
    });

    test('la pénalité d\'une passe vide le chrono : même règle', () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      // Passe avec la pénalité exacte : le chrono tombe à 0 sur le mot recyclé.
      p.game.turnEndTimestamp = DateTime.now().millisecondsSinceEpoch +
          p.settings.passPenalty * 1000 -
          100;
      p.passWord();
      p.endTurn();
      expect(p.game.timeRemaining, 0);
      validate(p, [...p.game.wordsGuessedThisTurn, p.game.expiredWord!]);
      p.nextRound();

      expectNormalTurnOf(p, 1, 0);
      expect(p.teams[0].scoreByRound[0], p.game.allWords.length);
    });

    test('un temps persisté négatif est traité comme 0', () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      buzzer(p);
      p.endTurn();
      p.game.timeRemaining = -3;
      validate(p, [...p.game.wordsGuessedThisTurn, p.game.expiredWord!]);
      p.nextRound();

      expectNormalTurnOf(p, 1, 0);
    });

    test('une continuation qui finit à son tour à 0 s passe aussi la main',
        () async {
      final p = await givenGame(3, wordsEach: 1);
      // M1 finie avec du temps par l'équipe 0, continuation en M2.
      playTurn(p, 99);
      p.nextRound();
      expect(p.isContinuation, isTrue);

      start(p);
      finishAtBuzzer(p);
      expect(p.game.history.last.isBonusContinuation, isTrue);
      p.nextRound();

      expectNormalTurnOf(p, 1, 0);
    });
  });

  group('Interdit de faire deviner et remplaçant', () {
    test('le piège tombe sur l\'équipe suivante, puis la rotation reste juste',
        () async {
      final p =
          await givenGame(2, fiesta: stock(['block_giver']), wordsEach: 1);
      final (a, b) = (p.teams[0], p.teams[1]);
      p.inflictMalus('block_giver', b.id, playerId: b.playerIds[0]);
      start(p);
      finishAtBuzzer(p);
      p.nextRound();

      // M2 : B commence, son premier joueur est bloqué, le 2e le remplace.
      expectNormalTurnOf(p, 1, 0);
      start(p);
      expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
      p.confirmGiverBlock();
      expect(p.getCurrentPlayer()!.id, b.playerIds[1]);
      playTurn(p, 1);
      expect(p.game.history.last.playerId, b.playerIds[1]);

      expectNormalTurnOf(p, 0, 1);
      playTurn(p, 1);
      expect(p.game.history.last.playerId, a.playerIds[1]);
      expectNormalTurnOf(p, 1, 2);
    });

    test('à son prochain tour, l\'équipe qui a fini à 0 s subit son piège',
        () async {
      // 🔴 `isContinuation` ne doit pas la croire encore en continuation : le
      // piège est ignoré sur une continuation.
      final p =
          await givenGame(2, fiesta: stock(['block_giver']), wordsEach: 1);
      final a = p.teams[0];
      start(p);
      finishAtBuzzer(p);
      p.nextRound();
      p.inflictMalus('block_giver', a.id, playerId: a.playerIds[1]);
      playTurn(p, 1);

      expectNormalTurnOf(p, 0, 1);
      start(p);
      expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
      p.confirmGiverBlock();
      expect(p.getCurrentPlayer()!.id, a.playerIds[2]);
      playTurn(p, 1);
      expect(p.game.history.last.playerId, a.playerIds[2]);
    });

    test('le prochain vrai tour de l\'équipe n\'est jamais une continuation',
        () async {
      final p = await givenGame(2, fiesta: stock(['plus_10s']), wordsEach: 1);
      start(p);
      finishAtBuzzer(p);
      p.nextRound();
      playTurn(p, 1);

      expectNormalTurnOf(p, 0, 1);
      p.toggleBonus('plus_10s');
      expect(p.turnTime.total, p.settings.turnDuration + 10,
          reason: 'le temps plein, pas un report');
    });
  });

  group('cartouches et effets', () {
    test('le tour est fini : ×2 et malus reçu ne passent pas à la suite',
        () async {
      final p = await givenGame(2,
          fiesta: stock(['double_points', 'no_pass']), wordsEach: 1);
      final (a, b) = (p.teams[0], p.teams[1]);
      playTurn(p, 1);
      // B envoie « Sans passe » à A puis joue.
      p.inflictMalus('no_pass', a.id);
      playTurn(p, 1);

      // A : ×2 et malus reçu, la manche finit à 0 s sur le chrono.
      p.toggleBonus('double_points');
      expect(p.passBlocked, isTrue);
      start(p);
      final before = p.teams[0].score;
      final mots = p.game.remainingWords.length;
      finishAtBuzzer(p);
      expect(p.teams[0].score, before + mots * 2,
          reason: '×2 sur tous ses mots');
      p.nextRound();

      expect(p.getCurrentTeam()!.id, b.id);
      expect(p.isDoublePointsOn, isFalse);
      expect(p.game.fiesta!.turn.charges, isEmpty);
      expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty,
          reason: 'le malus reçu est consommé');
      playTurn(p, 1);
      expect(p.game.history.last.points, 1);

      // Tour normal de A : plus de ×2, plus de malus, cartouche déjà dépensée.
      expect(p.getCurrentTeam()!.id, a.id);
      expect(p.isDoublePointsOn, isFalse);
      expect(p.passBlocked, isFalse);
      expect(left(p, 'double_points'), 0);
    });

    test('une cartouche non jouée reste en réserve', () async {
      final p = await givenGame(2, fiesta: stock(['plus_10s']), wordsEach: 1);
      start(p);
      finishAtBuzzer(p);
      p.nextRound();
      playTurn(p, 1);

      expect(left(p, 'plus_10s'), 1);
    });

    test(
        'un malus en attente sur l\'équipe suivante, impossible en M+1, est rendu',
        () async {
      // « Autre langue » ne se joue pas en M3. L'équipe suivante ne poursuit
      // rien : elle n'est pas `continuingTeamId`, la cartouche revient.
      final p =
          await givenGame(2, fiesta: stock(['other_language']), wordsEach: 1);
      final (a, b) = (p.teams[0], p.teams[1]);
      playTurn(p, 99);
      p.nextRound();
      // M2, continuation de A : envoie le malus à B et finit la manche à 0 s.
      expect(p.getCurrentTeam()!.id, a.id);
      p.inflictMalus('other_language', b.id);
      expect(left(p, 'other_language'), 0);
      start(p);
      finishAtBuzzer(p);
      p.nextRound();

      expect(p.getCurrentTeam()!.id, b.id);
      expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty);
      expect(p.game.fiesta!.cartridgesLeft('other_language', a.id), 1);
    });
  });

  group('retour arrière et reprise', () {
    test('depuis la transition : état restauré, aucun point doublé', () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      buzzer(p);
      p.endTurn();
      final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
      final expired = p.game.expiredWord!;
      validate(p, [...guessed, expired]);
      final total = p.game.allWords.length;
      expect(p.teams[0].score, total);

      p.restorePreValidationState();
      expect(p.game.currentScreen, AppConstants.screenVerification);
      expect(p.getCurrentTeam(), p.teams[0]);
      expect(p.game.currentPlayerIndexInTeam, 0);
      expect(p.game.currentTurnIndex, 0);
      expect(p.teams[0].score, 0);
      expect(p.game.history, isEmpty);
      expect(p.game.expiredWord, expired);
      p.clearRestoredValidatedWords();

      // Revalidé : mêmes points, une fois.
      validate(p, [...guessed, expired]);
      expect(p.teams[0].score, total);
      expect(p.game.history, hasLength(1));
      p.nextRound();
      expectNormalTurnOf(p, 1, 0);
    });

    test(
        'corriger en refusant le dernier mot : la manche continue, à l\'équipe suivante',
        () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      while (p.game.remainingWords.length > 1) {
        p.markWordAsGuessed();
      }
      buzzer(p);
      p.endTurn();
      final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
      validate(p, [...guessed, p.game.expiredWord!]);

      p.restorePreValidationState();
      p.clearRestoredValidatedWords();
      validate(p, guessed);

      expect(p.game.currentRound, 1);
      expect(p.game.remainingWords, hasLength(1));
      expectNormalTurnOf(p, 1, 0);
      expect(p.teams[0].score, guessed.length);
    });

    test('depuis l\'écran suivant : même restauration', () async {
      final p = await givenGame(2, wordsEach: 1);
      start(p);
      finishAtBuzzer(p);
      final total = p.teams[0].score;
      p.nextRound();
      expect(p.game.currentRound, 2);
      expect(p.canGoBackToVerification, isTrue);

      p.restorePreValidationState();
      expect(p.game.currentRound, 1);
      expect(p.game.currentScreen, AppConstants.screenVerification);
      expect(p.teams[0].score, 0);
      expect(p.getCurrentTeam(), p.teams[0]);
      final words = p.game.restoredValidatedWords!;
      p.clearRestoredValidatedWords();
      validate(p, words);
      expect(p.teams[0].score, total);
      p.nextRound();
      expectNormalTurnOf(p, 1, 0);
    });

    for (final (moment, advance) in [
      ('sur la transition', false),
      ('sur l\'avant-tour de M2', true),
    ]) {
      test('app tuée $moment : l\'équipe suivante, sans tour à 0 s', () async {
        final p = await givenGame(3, fiesta: stock(['plus_10s']), wordsEach: 1);
        start(p);
        finishAtBuzzer(p);
        if (advance) p.nextRound();
        await pumpEventQueue(times: 50);

        final revived = GameProvider();
        await pumpEventQueue(times: 50);
        expect(revived.game.currentRound, advance ? 2 : 1);
        expect(revived.game.turnBonusTime, isNull);
        expect(revived.game.pendingBonusTurnId, isNull);
        if (!advance) revived.nextRound();

        expectNormalTurnOf(revived, 1, 0);
        expect(revived.teams[0].score, p.teams[0].score);
        playTurn(revived, 1);
        expect(revived.game.history.last.isBonusContinuation, isFalse);
        expect(revived.game.history.last.teamId, revived.teams[1].id);
      });
    }
  });

  test('défi surprise : même enchaînement, puis l\'équipe suivante', () async {
    final p = await givenGame(2,
        fiesta: stock(['plus_10s', 'no_pass', 'free_pass'], challenges: true),
        wordsEach: 2);
    for (var round = 1; round <= 2; round++) {
      final team = p.teams.indexOf(p.getCurrentTeam()!);
      start(p);
      finishAtBuzzer(p);
      p.nextRound();
      if (p.game.currentScreen == AppConstants.screenChallenge) {
        expect(p.currentChallenge, isNotNull);
        p.finishChallenge();
      }
      expectNormalTurnOf(p, 1 - team, round == 1 ? 0 : 1);
    }
  });

  test('manche 3 : rien ne change, la partie se termine', () async {
    final p = await givenGame(2, wordsEach: 1);
    playTurn(p, 99);
    p.nextRound();
    playTurn(p, 99);
    p.nextRound();
    expect(p.game.currentRound, 3);
    final team = p.getCurrentTeam()!.id;

    start(p);
    finishAtBuzzer(p);
    expect(p.game.currentRound, 3);
    expect(p.getCurrentTeam()!.id, team, reason: 'pas de rotation à la fin');
    p.nextRound();
    expect(p.game.currentScreen, AppConstants.screenResults);

    await pumpEventQueue(times: 50);
    final archive = (await GameHistoryService().load()).single;
    expect(archive.winners.single.id, p.getTeamsSortedByScore().first.id);
    expect(archive.ranking.map((t) => t.score),
        p.getTeamsSortedByScore().map((t) => t.score));
  });

  test('égalité après un tour sans report : le dernier à commencer gagne',
      () async {
    final p = await givenGame(2, wordsEach: 1);
    // M1 : tous les mots en deux tours, la 2e équipe finit à 0 s.
    final total = p.game.allWords.length;
    playTurn(p, total ~/ 2);
    start(p);
    finishAtBuzzer(p);
    p.nextRound();
    expectNormalTurnOf(p, 0, 1);

    // M2 et M3 répartis à égalité : l'ordre de jeu ne bouge pas.
    for (final round in [2, 3]) {
      playTurn(p, total ~/ 2);
      expect(p.game.currentRound, round);
      playTurn(p, 99);
      p.nextRound();
      if (round < 3) {
        expect(p.isContinuation, isTrue);
        playTurn(p, 0);
      }
    }
    expect(p.game.teamPlayOrder, [0, 1]);
    expect(p.teams[0].score, p.teams[1].score);
    expect(p.getTeamsSortedByScore().first.id, p.teams[1].id);
  });
}
