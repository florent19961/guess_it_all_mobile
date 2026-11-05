import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// 2 équipes d'un joueur, [wordsEach] mots chacun.
Future<GameProvider> givenProvider({int wordsEach = 3}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  provider.updateSettings(numberOfTeams: 2);
  for (final name in ['Ana', 'Bob']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(
        id, [for (var i = 0; i < wordsEach; i++) 'mot-$name-$i']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Sans tirage : [ids] en cartouche, [charges] par équipe pour la partie.
FiestaRules stock(List<String> ids, {int charges = 2, int boostCount = 0}) =>
    FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 0,
      boostCount: boostCount,
      modifiers: {
        for (final id in ids)
          id: ModifierSetting(
              active: true,
              rounds: const {1, 2, 3},
              mode: ModifierMode.cartridge,
              charges: charges),
      },
    );

/// L'équipe qui joue fait deviner [n] mots, tour validé. Rend son id.
String playTurn(GameProvider p, [int n = 0]) {
  final teamId = p.getCurrentTeam()!.id;
  p.startTurn();
  p.startTurnTimer();
  for (var i = 0; i < n; i++) {
    p.markWordAsGuessed();
  }
  if (p.game.currentScreen != AppConstants.screenVerification) p.endTurn();
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);
  return teamId;
}

int left(GameProvider p, String id) =>
    p.reserve.firstWhere((c) => c.catalogId == id).left;

String? blocked(GameProvider p, String id) =>
    p.reserve.firstWhere((c) => c.catalogId == id).blockedReason;

void main() {
  test(
      'la menée qui vient de finir M1 a sa réserve complète dans sa '
      'continuation, cartouche gagnée à l\'instant comprise', () async {
    final p = await givenProvider();
    await p.startGame(fiesta: stock(['plus_10s'], charges: 0, boostCount: 1));
    final leader = playTurn(p, 4);
    final trailing = playTurn(p, 99);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.game.fiesta!.earned, isEmpty);
    p.nextRound();

    expect(p.getCurrentTeam()!.id, trailing);
    expect(p.getCurrentTeam()!.id, isNot(leader));
    expect(p.isContinuation, isTrue);
    expect(left(p, 'plus_10s'), 1);
    expect(p.reserve.single.usable, isTrue);
  });

  test(
      '+10 s allumé en continuation : temps reporté + 10 s, aperçu et chrono '
      'd\'accord, annulable avant le départ, dépensé au départ, récap juste',
      () async {
    final p = await givenProvider();
    await p.startGame(fiesta: stock(['plus_10s']));
    final team = playTurn(p, 99);
    p.nextRound();
    final carried = p.game.turnBonusTime!;

    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, carried + 10);
    expect(p.turnTime.lines.map((l) => l.seconds), [carried, 10]);
    expect(left(p, 'plus_10s'), 1);
    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, carried);
    expect(left(p, 'plus_10s'), 2);
    expect(p.game.fiesta!.chargesUsed, isEmpty);

    p.toggleBonus('plus_10s');
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.turnTime.total, carried + 10, reason: 'app tuée');

    p.startTurn();
    expect(p.game.timeRemaining, carried + 10);
    p.startTurnTimer();
    expect(p.game.turnAllottedSeconds, carried + 10);
    final use = p.game.fiesta!.chargesUsed.single;
    expect((use.catalogId, use.teamId, use.round), ('plus_10s', team, 2));
    p.endTurn();
    p.savePreValidationState(const []);
    p.validateWords(const []);

    expect(p.game.fiesta!.turn.isEmpty, isTrue);
    expect(p.modifierRecap.last.title, 'Cartouches utilisées');
    expect(p.modifierRecap.last.detail,
        'Bonus de 10 s, ${p.getTeamById(team)!.name} en M2');
  });

  test(
      'une charge dépensée sur la partie de ce tour reste comptée une seule '
      'fois, son effet continue, elle ne se rallume pas ; un autre bonus '
      's\'allume', () async {
    final p = await givenProvider();
    await p.startGame(
        fiesta: stock(['double_points', 'plus_10s', 'free_pass']));
    p.toggleBonus('double_points');
    p.toggleBonus('plus_10s');
    playTurn(p, 99);
    p.nextRound();
    final carried = p.game.turnBonusTime!;

    expect(p.isContinuation, isTrue);
    expect(p.isDoublePointsOn, isTrue);
    expect(left(p, 'double_points'), 1, reason: 'pas de double décompte');
    expect(blocked(p, 'double_points'), 'déjà en cours ce tour');
    expect(blocked(p, 'plus_10s'), 'déjà en cours ce tour');
    expect(p.turnTime.total, carried, reason: 'le +10 s ne se rejoue pas');

    p.toggleBonus('double_points');
    p.toggleBonus('plus_10s');
    expect(p.isDoublePointsOn, isTrue, reason: 'ni éteint ni rallumé');
    expect(p.game.fiesta!.chargesUsed, hasLength(2));

    expect(p.isBonusArmed('double_points'), isFalse);
    p.toggleBonus('free_pass');
    expect(p.isBonusArmed('free_pass'), isTrue);
    p.startTurn();
    p.startTurnTimer();
    expect(p.isFreePassOn, isTrue);
    expect(p.game.fiesta!.chargesUsed, hasLength(3));
    expect(p.game.fiesta!.chargesUsed.last.round, 2);
  });

  test(
      'un −10 s déjà appliqué au tour ne se réapplique pas sur le report : '
      'temps reporté, + 10 s éventuels seulement', () async {
    final p = await givenProvider();
    await p.startGame(fiesta: stock(['minus_10s', 'plus_10s']));
    final b = p.teams.singleWhere((t) => t.id != p.getCurrentTeam()!.id).id;
    expect(p.inflictMalus('minus_10s', b), isNull);
    playTurn(p);
    expect(p.getCurrentTeam()!.id, b);
    expect(p.turnTime.total, 20);
    playTurn(p, 99);
    p.nextRound();
    final carried = p.game.turnBonusTime!;

    expect(p.isContinuation, isTrue);
    expect(p.receivedThisTurn.map((m) => m.catalogId), ['minus_10s']);
    expect(p.turnTime.total, carried);
    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, carried + 10);
  });

  test(
      'malus infligé en continuation : annulable avant le départ, pèse sur le '
      'prochain tour de la cible. Celui de la première partie du tour n\'est '
      'plus annulable', () async {
    final p = await givenProvider();
    await p.startGame(fiesta: stock(['reversed', 'no_pass']));
    final a = p.getCurrentTeam()!.id;
    final b = p.teams.singleWhere((t) => t.id != a).id;
    expect(p.inflictMalus('reversed', b), isNull);
    playTurn(p, 99);
    p.nextRound();

    expect(p.isContinuation, isTrue);
    expect(p.sentThisTurn, isEmpty, reason: 'envoyé avant ce départ');
    expect(left(p, 'reversed'), 1);

    expect(p.inflictMalus('no_pass', b), isNull);
    expect(left(p, 'no_pass'), 1);
    expect(p.sentThisTurn.map((m) => m.catalogId), ['no_pass']);
    p.cancelSent(p.sentThisTurn.single);
    expect(left(p, 'no_pass'), 2);
    expect(p.game.fiesta!.chargesUsed.map((u) => u.catalogId), ['reversed']);
    expect(p.inflictMalus('no_pass', b), isNull);

    playTurn(p);
    expect(p.getCurrentTeam()!.id, b);
    expect(p.receivedThisTurn.map((m) => m.catalogId), ['reversed', 'no_pass']);
    playTurn(p);
    expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty);
  });

  test(
      '×2 dépensé en continuation qui vide le pool : points doublés, tour clos ; '
      'la continuation suivante repart à vide et peut en rallumer un',
      () async {
    final p = await givenProvider(wordsEach: 1);
    await p.startGame(fiesta: stock(['double_points']));
    final team = playTurn(p, 99);
    final rounds = () => p.getTeamById(team)!.scoreByRound;
    expect(rounds(), [2, 0, 0]);
    p.nextRound();

    p.setDoublePoints(true);
    expect(p.isDoublePointsArmed, isTrue);
    playTurn(p, 99);
    expect(rounds(), [2, 4, 0]);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.game.fiesta!.turn.isEmpty, isTrue);
    p.nextRound();

    expect(p.isContinuation, isTrue);
    expect(p.isDoublePointsOn, isFalse);
    expect(left(p, 'double_points'), 1);
    expect(blocked(p, 'double_points'), isNull);
    p.setDoublePoints(true);
    playTurn(p, 99);
    expect(rounds(), [2, 4, 4]);
    expect(p.game.currentScreen, AppConstants.screenResults);
    final name = p.getTeamById(team)!.name;
    expect(p.modifierRecap.last.detail,
        'Mot compte double, $name en M2 · Mot compte double, $name en M3');
  });
}
