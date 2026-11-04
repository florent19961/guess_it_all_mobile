import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Une équipe d'un joueur par nom, [wordsEach] mots chacun.
Future<GameProvider> givenProvider(List<String> names,
    {int wordsEach = 5}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  provider.updateSettings(numberOfTeams: names.length);
  for (final name in names) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(
        id, [for (var i = 0; i < wordsEach; i++) 'mot-$name-$i']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Personnalisé, sans tirage : [ids] « En stock », 2 cartouches par équipe et
/// par manche, sur leurs manches possibles.
FiestaRules stock(Map<String, Set<int>> ids) => FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 0,
      modifiers: {
        for (final e in ids.entries)
          e.key: ModifierSetting(
              active: true,
              rounds: e.value,
              mode: ModifierMode.stock,
              charges: 2),
      },
    );

/// L'équipe qui joue fait deviner [n] mots, puis le tour est validé. Rend
/// l'id de l'équipe qui a joué.
String playTurn(GameProvider provider, [int n = 0]) {
  final teamId = provider.getCurrentTeam()!.id;
  provider.startTurn();
  provider.startTurnTimer();
  for (var i = 0; i < n; i++) {
    provider.markWordAsGuessed();
  }
  if (provider.game.currentScreen != AppConstants.screenVerification) {
    provider.endTurn();
  }
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
  return teamId;
}

int left(GameProvider p, String id) =>
    p.reserve.firstWhere((c) => c.catalogId == id).left;

List<String> received(GameProvider p) =>
    p.receivedThisTurn.map((m) => '${m.catalogId}<${m.fromTeamId}').toList();

String name(GameProvider p, String teamId) => p.getTeamById(teamId)!.name;

void main() {
  test(
      '3 équipes : le malus vise le PROCHAIN tour de sa cible ; même malus '
      'déjà infligé → refus (message exact), cartouche non consommée ; un '
      'malus différent se cumule ; app tuée : envois et cartouches relus ; '
      'consommés à la fin du tour visé', () async {
    var p = await givenProvider(['Ana', 'Bob', 'Cid']);
    await p.startGame(
        fiesta: stock({
      'minus_10s': {1},
      'reversed': {1}
    }));
    // Ordre de jeu : a, b, c.
    final a = playTurn(p);
    final b = playTurn(p);
    final c = playTurn(p);
    expect(p.getCurrentTeam()!.id, a);

    expect(p.inflictMalus('minus_10s', c), isNull);
    expect(left(p, 'minus_10s'), 1);
    expect(received(p), isEmpty, reason: 'rien sur l\'envoyeuse');
    playTurn(p);

    // b : même malus sur c → refusé, rien consommé ; un autre se cumule.
    expect(
        p.inflictMalus('minus_10s', c),
        'Impossible : Malus de 10 s est déjà infligé à l\'équipe '
        '${name(p, c)} par l\'équipe ${name(p, a)} pour son prochain tour. '
        'Choisis un autre malus ou attends.');
    expect(left(p, 'minus_10s'), 2);
    expect(p.inflictMalus('reversed', c), isNull);

    // App tuée avant le tour de b.
    await pumpEventQueue();
    p = GameProvider();
    await pumpEventQueue();
    expect(p.getCurrentTeam()!.id, b);
    expect(left(p, 'reversed'), 1);
    expect(
        p.sentThisTurn.map((m) => (m.catalogId, m.teamId)), [('reversed', c)]);
    playTurn(p);

    // Tour de c : les deux malus reçus, le −10 s compte.
    expect(p.getCurrentTeam()!.id, c);
    expect(received(p), ['minus_10s<$a', 'reversed<$b']);
    expect(p.isWordReversed, isTrue);
    expect(p.turnTime.total, 20);
    playTurn(p);

    // Consommés : plus rien au tour suivant de c ; les cartouches dépensées
    // restent dépensées.
    expect(p.getCurrentTeam()!.id, a);
    expect(left(p, 'minus_10s'), 1);
    playTurn(p);
    playTurn(p);
    expect(p.getCurrentTeam()!.id, c);
    expect([received(p), p.isWordReversed], [isEmpty, false]);
  });

  test(
      'Annulation avant le tour : la cartouche revient ; au départ du tour, '
      'la Passe gratuite allumée est dépensée UNE fois (2 passes ce tour '
      'seulement) et l\'envoi n\'est plus annulable', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(
        fiesta: stock({
      'free_pass': {1},
      'minus_10s': {1}
    }));
    final a = p.getCurrentTeam()!.id;
    final b = p.teams.firstWhere((t) => t.id != a).id;

    // Bonus : allumé = sort de la réserve, rien de dépensé avant le départ.
    p.toggleBonus('free_pass');
    expect(p.bonusesThisTurn, ['free_pass']);
    expect(left(p, 'free_pass'), 1);
    p.toggleBonus('free_pass');
    expect([p.bonusesThisTurn, left(p, 'free_pass')], [isEmpty, 2]);
    p.toggleBonus('free_pass');

    // Malus envoyé puis annulé : tout revient.
    expect(p.inflictMalus('minus_10s', b), isNull);
    p.cancelSent(p.sentThisTurn.single);
    expect(left(p, 'minus_10s'), 2);
    expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty);
    expect(p.game.fiesta!.chargesUsed, isEmpty);
    expect(p.inflictMalus('minus_10s', b), isNull);

    p.startTurn();
    p.startTurnTimer();
    expect(p.sentThisTurn, isEmpty, reason: 'tour commencé');
    expect(p.game.fiesta!.chargesUsed.map((u) => (u.catalogId, u.targetTeamId)),
        [('minus_10s', b), ('free_pass', null)]);
    expect(p.freePasses, 2);
    p.passWord();
    p.passWord();
    expect(p.currentPassPenalty, 5);
    p.endTurn();
    p.savePreValidationState(const []);
    p.validateWords(const []);

    // b subit le −10 s ; au tour suivant de a, la Passe gratuite n'a pas
    // été redépensée.
    expect(p.turnTime.total, 20);
    playTurn(p);
    expect(p.getCurrentTeam()!.id, a);
    expect(p.freePasses, 0);
    expect(left(p, 'free_pass'), 1);
    expect(p.game.fiesta!.chargesUsed.where((u) => u.catalogId == 'free_pass'),
        hasLength(1));
  });

  test(
      'Manche 3 (Explosif) : un seul mime par tour de la cible — un second '
      'mime est refusé sans consommer, un mime vers une autre équipe passe',
      () async {
    final p = await givenProvider(['Ana', 'Bob', 'Cid'], wordsEach: 1);
    await p.startGame(
        fiesta: stock({
      'mime_no_arms': {3},
      'mime_eyes_closed': {3}
    }));
    for (var round = 1; round < 3; round++) {
      playTurn(p, 99);
      p.nextRound();
    }
    expect(p.reserve, isEmpty, reason: 'continuation : rien ne s\'y joue');
    final t0 = playTurn(p); // continuation
    final x = p.getCurrentTeam()!.id;
    expect(p.inflictMalus('mime_no_arms', t0), isNull);
    final y = p.teams.firstWhere((t) => t.id != t0 && t.id != x).id;
    playTurn(p);
    expect(p.getCurrentTeam()!.id, y);

    expect(p.inflictMalus('mime_eyes_closed', t0), startsWith('Impossible : '));
    expect(left(p, 'mime_eyes_closed'), 2);
    expect(p.inflictMalus('mime_eyes_closed', x), isNull);
    expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null).length, 2);
  });

  test(
      'Malus interdit dans la manche où la cible rejoue (« Autre langue » '
      'envoyé en M2, cible qui rejoue en M3) : sans effet, il part à la fin '
      'de son tour', () async {
    final p = await givenProvider(['Ana', 'Bob', 'Cid'], wordsEach: 1);
    await p.startGame(
        fiesta: stock({
      'other_language': {2}
    }));
    playTurn(p, 99);
    p.nextRound();
    final victim = playTurn(p); // continuation M2
    expect(p.inflictMalus('other_language', victim), isNull);
    playTurn(p, 99); // l'envoyeuse finit M2
    p.nextRound();
    while (p.getCurrentTeam()!.id != victim) {
      playTurn(p);
    }
    expect(p.receivedThisTurn, isEmpty);
    playTurn(p);
    expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty);
  });

  test(
      'Malus envoyé en fin de M1, la cible rejoue en M2 sous une règle de '
      'manche incompatible (« Passe gratuite » Toujours) : écarté sans effet, '
      'puis retiré à la fin de son tour', () async {
    final p = await givenProvider(['Ana', 'Bob'], wordsEach: 1);
    await p.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        drawCount: 0,
        modifiers: {
          'no_pass': ModifierSetting(
              active: true, rounds: const {1}, mode: ModifierMode.stock),
          'free_pass': ModifierSetting(
              active: true, rounds: const {2}, mode: ModifierMode.always),
        },
      ),
    );
    final a = p.getCurrentTeam()!.id;
    final b = p.teams.firstWhere((t) => t.id != a).id;
    expect(p.inflictMalus('no_pass', b), isNull);
    playTurn(p, 99); // a finit M1
    p.nextRound();
    expect(playTurn(p), a); // continuation de a en M2

    expect(p.getCurrentTeam()!.id, b);
    expect(p.receivedThisTurn, isEmpty);
    expect([p.passBlocked, p.freePasses], [false, 2]);
    playTurn(p);
    expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty);
  });

  test(
      'Coup de pouce (Auto) : la Passe gratuite offerte est UNE cartouche — '
      'allumée, 2 passes gratuites ce tour-là, puis plus rien', () async {
    var p = await givenProvider(['Ana', 'Bob'], wordsEach: 2);
    await p.startGame(fiesta: FiestaRules(mode: FiestaMode.auto));
    // Graine fixée : un tirage de M2 qui laisse la Passe gratuite utile.
    final rules = p.game.fiesta!.rules;
    final gameId = [
      for (var i = 0; i < 100; i++) 'g$i'
    ].firstWhere((id) => roundModifiers(rules, gameId: id, round: 2)
        .every((m) => m.catalogId != 'free_pass' && m.catalogId != 'no_pass'));
    await pumpEventQueue();
    final saved = (await StorageService().loadGameState())!;
    saved['game']['gameId'] = gameId;
    await StorageService().saveGameState(saved);
    p = GameProvider();
    await pumpEventQueue();

    // M1 : 1 mot contre 3 → écart 2, coup de pouce « léger » pour la menée.
    final trailing = playTurn(p, 1);
    playTurn(p, 99);
    expect(
        p.appBoostPreview
            .where((m) => m.teamId == trailing)
            .map((m) => (m.catalogId, m.charges)),
        [('free_pass', 1)]);
    p.nextRound();
    playTurn(p); // continuation du leader

    expect(p.getCurrentTeam()!.id, trailing);
    expect(left(p, 'free_pass'), 1);
    expect(p.freePasses, 0, reason: 'pas toute la manche');
    p.toggleBonus('free_pass');
    p.startTurn();
    p.startTurnTimer();
    expect(p.freePasses, 2);
    p.passWord();
    p.passWord();
    expect(p.currentPassPenalty, 5);
    p.endTurn();
    p.savePreValidationState(const []);
    p.validateWords(const []);
    playTurn(p);

    expect(p.getCurrentTeam()!.id, trailing);
    expect([p.freePasses, left(p, 'free_pass')], [0, 0]);
  });
}
