import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/score_timeline.dart';
import 'package:guess_it_all_mobile/models/stats_aggregation.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Le chrono avance de [seconds] sans attendre.
void elapse(GameProvider p, int seconds) {
  p.game.turnEndTimestamp = p.game.turnEndTimestamp! - seconds * 1000;
}

void guess(GameProvider p, int words) {
  for (var i = 0; i < words; i++) {
    p.markWordAsGuessed();
  }
}

void validateGuessed(GameProvider p) {
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);
}

void main() {
  test(
      'partie Fiesta calculée à la main : mêmes chiffres partout, ×2, piège, '
      'continuations et correction comprises', () async {
    await givenPrefs();
    givenFakePlatformPlugins();
    final p = GameProvider();
    await pumpEventQueue();
    p.updateSettings(numberOfTeams: 2);
    final ids = <String>[];
    for (var i = 0; i < 4; i++) {
      final id = (p.addPlayer('J$i')['player'] as dynamic).id as String;
      p.updatePlayerWords(id, ['m$i-0', 'm$i-1']);
      ids.add(id);
    }
    p.createTeams();
    for (var i = 0; i < 4; i++) {
      p.movePlayerToTeam(ids[i], p.teams[i < 2 ? 0 : 1].id);
    }
    await p.startGame(
      fiesta: FiestaRules(
        drawCount: 0,
        trailingCount: 0,
        modifiers: {
          'double_points': ModifierSetting(charges: 1),
          'block_giver': ModifierSetting(charges: 1),
        },
      ),
    );

    // Ordre fixé : A puis B, joueurs dans l'ordre.
    final fixed = p.game.toJson()
      ..['teamPlayOrder'] = [0, 1]
      ..['playerOrderByTeam'] = {
        for (final t in p.teams)
          t.id: List<int>.generate(t.playerIds.length, (i) => i),
      }
      ..['currentTeamIndex'] = 0
      ..['currentPlayerIndexInTeam'] = 0
      ..['currentTurnIndex'] = 0;
    p.goToScreen(AppConstants.screenVerification);
    p.savePreValidationState(const []);
    p.game.preValidationSnapshot!['game'] = fixed;
    p.restorePreValidationState();
    p.goToScreen(AppConstants.screenGame);

    final (a, b) = (p.teams[0].id, p.teams[1].id);
    final (j0, j1, j2, j3) = (ids[0], ids[1], ids[2], ids[3]);
    expect(p.game.allWords, hasLength(8));

    // M1 — A/J0 : ×2, envoie « Interdit » à J2 ; 2 mots en 10 s, 4 points.
    p.toggleBonus('double_points');
    p.inflictMalus('block_giver', b, playerId: j2);
    p.startTurn();
    p.startTurnTimer();
    elapse(p, 10);
    guess(p, 2);
    p.endTurn();
    validateGuessed(p);

    // M1 — B : piège sur J2, J3 le remplace ; 1 mot, chrono épuisé (30 s).
    p.startTurn();
    p.startTurnTimer();
    expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
    p.confirmGiverBlock();
    p.startTurn();
    p.startTurnTimer();
    guess(p, 1);
    elapse(p, 30);
    p.endTurn();
    validateGuessed(p);

    // M1 — A/J1 : les 5 derniers mots en 12 s, 18 s reportées.
    p.startTurn();
    p.startTurnTimer();
    elapse(p, 12);
    guess(p, 5);
    expect(p.game.turnBonusTime, 18);
    validateGuessed(p);
    p.nextRound();

    // M2 — A/J1 continue 18 s : 3 mots en 8 s. Une première validation à 2 mots
    // est corrigée par retour arrière : pas de doublon.
    expect(p.isContinuation, isTrue);
    p.startTurn();
    p.startTurnTimer();
    elapse(p, 8);
    guess(p, 3);
    p.endTurn();
    final trois = List<String>.from(p.game.wordsGuessedThisTurn);
    p.savePreValidationState(trois.take(2).toList());
    p.validateWords(trois.take(2).toList());
    p.restorePreValidationState();
    p.clearRestoredValidatedWords();
    p.savePreValidationState(trois);
    p.validateWords(trois);

    // M2 — B/J2 : les 5 derniers mots en 6 s, 24 s reportées.
    p.startTurn();
    p.startTurnTimer();
    elapse(p, 6);
    guess(p, 5);
    validateGuessed(p);
    p.nextRound();

    // M3 — B/J2 continue : les 8 mots en 4 s.
    p.startTurn();
    p.startTurnTimer();
    elapse(p, 4);
    guess(p, 8);
    validateGuessed(p);
    p.nextRound();
    expect(p.game.currentScreen, AppConstants.screenResults);

    // Résultats : A 4 + 5 / 3 / 0 = 12 ; B 1 / 5 / 8 = 14.
    expect(p.getTeamById(a)!.scoreByRound, [9, 3, 0]);
    expect(p.getTeamById(a)!.score, 12);
    expect(p.getTeamById(b)!.scoreByRound, [1, 5, 8]);
    expect(p.getTeamById(b)!.score, 14);
    expect(p.getTeamsSortedByScore().map((t) => t.id), [b, a]);

    // Pas d'entrée fantôme : 6 tours joués, 2 continuations.
    final history = p.game.history;
    expect(history.map((h) => h.playerId), [j0, j3, j1, j1, j2, j2]);
    expect(history.map((h) => h.timeSpent), [10, 30, 12, 8, 6, 4]);
    expect(history.map((h) => h.isBonusContinuation),
        [false, false, false, true, false, true]);

    // Top joueurs : des MOTS, le ×2 ne compte pas.
    String rows(List<StatRow> r) =>
        r.map((x) => '${x.playerId}=${x.label}').join(' ');
    expect(rows(guessedWordsRanking(history)), '$j2=13 $j1=8 $j0=2 $j3=1');
    expect(rows(guessedWordsRanking(history, round: 1)), '$j1=5 $j0=2 $j3=1');
    expect(rows(guessedWordsRanking(history, round: 2)), '$j2=5 $j1=3');
    expect(rows(guessedWordsRanking(history, round: 3)), '$j2=8');

    // Temps moyen : J2 10 s / 13, J1 20 s / 8, J0 10 s / 2, J3 30 s / 1.
    expect(rows(averageTimePerWordRanking(history)),
        '$j2=0.8s $j1=2.5s $j0=5.0s $j3=30.0s');
    expect(rows(averageTimePerWordRanking(history, round: 2)),
        '$j2=1.2s $j1=2.7s');

    // Révélation : les courbes finissent sur les totaux ; les cartouches jouées
    // sont datées du 1er tour de A.
    final timeline = buildScoreTimeline(teamIds: [a, b], history: history);
    expect(timeline.series[0], [0, 4, 4, 9, 12, 12, 12]);
    expect(timeline.series[1], [0, 0, 1, 1, 1, 6, 14]);
    expect(p.game.fiesta!.chargesUsed.map((u) => entryOfCharge(u, history)),
        [0, 0]);

    // Récap : les deux cartouches, une seule fois chacune.
    expect(p.modifierRecap.map((l) => l.title), ['Cartouches utilisées']);
    expect(p.modifierRecap.single.detail.split(' · '), hasLength(2));

    // Historique : mêmes chiffres, même classement, jamais d'égalité.
    await pumpEventQueue(times: 50);
    final archive = (await GameHistoryService().load()).single;
    expect(archive.ranking.map((t) => t.id), [b, a]);
    expect(archive.ranking.map((t) => t.score), [14, 12]);
    expect(archive.ranking.map((t) => t.scoreByRound), [
      [1, 5, 8],
      [9, 3, 0]
    ]);
    expect(archive.isTie, isFalse);
    expect(archive.winners.single.id, b);
  });
}
