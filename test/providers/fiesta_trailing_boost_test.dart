import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Une équipe d'un joueur par nom, [wordsEach] mots chacun.
Future<GameProvider> givenProvider(List<String> names,
    {int wordsEach = 2}) async {
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

ModifierSetting cartridge(int charges) => ModifierSetting(
    active: true,
    rounds: const {1, 2, 3},
    mode: ModifierMode.cartridge,
    charges: charges);

/// [ids] en cartouche à [charges] pour la partie, coup de pouce allumé si
/// [boost].
FiestaRules cartridges(List<String> ids,
        {int charges = 0, bool boost = true}) =>
    FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 0,
      trailingBoost: boost,
      modifiers: {for (final id in ids) id: cartridge(charges)},
    );

/// L'équipe qui joue fait deviner [n] mots, puis le tour est validé. Rend
/// l'id de l'équipe qui a joué.
String playTurn(GameProvider p, [int n = 0]) {
  final teamId = p.getCurrentTeam()!.id;
  p.startTurn();
  p.startTurnTimer();
  for (var i = 0;
      i < n && p.game.currentScreen == AppConstants.screenTurn;
      i++) {
    p.markWordAsGuessed();
  }
  if (p.game.currentScreen != AppConstants.screenVerification) p.endTurn();
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);
  return teamId;
}

/// La première équipe fait 1 point, l'autre finit la manche : rend (menée,
/// en tête), écran de transition.
(String, String) finishRoundWithGap(GameProvider p) {
  final trailing = playTurn(p, 1);
  final leader = playTurn(p, 99);
  expect(p.game.currentScreen, AppConstants.screenTransition);
  return (trailing, leader);
}

int left(GameProvider p, String id) =>
    p.reserve.where((c) => c.catalogId == id).firstOrNull?.left ?? 0;

List<String> earned(GameProvider p) =>
    p.game.fiesta!.earned.map((e) => '${e.catalogId}/${e.teamId}').toList();

Future<GameProvider> reload() async {
  await pumpEventQueue();
  final p = GameProvider();
  await pumpEventQueue();
  return p;
}

void main() {
  test(
      'la menée gagne sa cartouche à « Manche suivante », jamais avant ; le '
      'leader rien ; elle reste jusqu\'à la fin de la partie', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['plus_10s']));
    expect(p.reserve, isEmpty, reason: 'à 0 : rien au départ');

    final (trailing, leader) = finishRoundWithGap(p);
    expect(p.game.fiesta!.earned, isEmpty,
        reason: 'la transition n\'écrit rien');
    p.nextRound();
    expect(earned(p), ['plus_10s/$trailing']);

    // Continuation du leader, puis la menée joue M2 sans la dépenser.
    expect(p.reserve, isEmpty);
    expect(playTurn(p), leader);
    expect(p.getCurrentTeam()!.id, trailing);
    expect(left(p, 'plus_10s'), 1);
    expect(playTurn(p, 99), trailing);
    p.nextRound();

    // En M3 elle l'a encore (le coup de pouce d'après M2 ne touche que le
    // non-leader du moment) : stock = gagnées − dépensées, toutes manches.
    expect(p.game.currentRound, 3);
    final owned = p.game.fiesta!.cartridgesLeft('plus_10s', trailing);
    expect(owned, greaterThanOrEqualTo(1));
    while (p.getCurrentTeam()!.id != trailing || p.isContinuation) {
      playTurn(p);
    }
    expect(left(p, 'plus_10s'), owned);
    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, 40);
    expect(playTurn(p), trailing);
    expect(p.game.fiesta!.cartridgesLeft('plus_10s', trailing), owned - 1);
  });

  test(
      'retour arrière depuis la transition puis correction : ni doublon ni '
      'perte, et le cadeau suit le classement corrigé', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['plus_10s']));
    final (trailing, leader) = finishRoundWithGap(p);

    // Retour à la vérification, on invalide tout : plus de fin de manche.
    p.restorePreValidationState();
    p.savePreValidationState(const []);
    p.validateWords(const []);
    expect(p.game.currentScreen, AppConstants.screenGame);
    expect(p.game.fiesta!.earned, isEmpty);

    // L'ancienne menée finit la manche et passe devant : le cadeau change de
    // main.
    expect(playTurn(p, 99), trailing);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    p.nextRound();
    expect(earned(p), ['plus_10s/$leader']);
  });

  test(
      'retour arrière depuis l\'avant-tour de la manche suivante, puis '
      'revalidation : la cartouche n\'est pas doublée', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['plus_10s']));
    final (trailing, _) = finishRoundWithGap(p);
    p.nextRound();
    expect(earned(p), ['plus_10s/$trailing']);

    // Le snapshot d'avant validation est restauré : état de fin de M1.
    expect(p.canGoBackToVerification, isTrue);
    p.restorePreValidationState();
    expect(p.game.fiesta!.earned, isEmpty);
    final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
    p.savePreValidationState(guessed);
    p.validateWords(guessed);
    p.nextRound();
    expect(earned(p), ['plus_10s/$trailing']);
  });

  test('app tuée sur la transition, puis après : ni doublon ni perte',
      () async {
    var p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['plus_10s']));
    final (trailing, _) = finishRoundWithGap(p);

    p = await reload();
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.game.fiesta!.earned, isEmpty);
    p.nextRound();
    p.nextRound(); // double tap
    expect(earned(p), ['plus_10s/$trailing']);

    p = await reload();
    expect(earned(p), ['plus_10s/$trailing']);
    expect(p.game.fiesta!.cartridgesLeft('plus_10s', trailing), 1);
  });

  test(
      'un malus gagné va en réserve : il s\'inflige, personne ne le subit tout '
      'seul', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['reversed']));
    final (trailing, leader) = finishRoundWithGap(p);
    p.nextRound();
    expect(earned(p), ['reversed/$trailing']);
    expect(p.isWordReversed, isFalse, reason: 'pas de malus au leader');
    playTurn(p); // continuation

    expect(p.getCurrentTeam()!.id, trailing);
    expect(left(p, 'reversed'), 1);
    expect(p.inflictMalus('reversed', leader), isNull);
    expect(left(p, 'reversed'), 0);
    playTurn(p);
    expect(p.getCurrentTeam()!.id, leader);
    expect(p.isWordReversed, isTrue);
  });

  test(
      'stock pour la partie : les cartouches ne reviennent pas à la manche '
      'suivante, un mime reste caché hors M3', () async {
    final p = await givenProvider(['Ana', 'Bob'], wordsEach: 1);
    await p.startGame(
        fiesta: cartridges(['free_pass', 'mime_no_arms'],
            charges: 2, boost: false));
    final first = p.getCurrentTeam()!.id;
    expect(p.reserve.map((c) => c.catalogId), ['free_pass'],
        reason: 'mime caché avant M3');
    expect(left(p, 'free_pass'), 2);

    p.toggleBonus('free_pass');
    playTurn(p, 99); // fin de M1, cartouche dépensée
    p.nextRound();
    playTurn(p, 99); // continuation qui finit M2
    p.nextRound();
    expect(p.game.currentRound, 3);
    playTurn(p); // continuation

    final second = p.getCurrentTeam()!.id;
    expect(second, isNot(first));
    expect(p.reserve.map((c) => (c.catalogId, c.left)),
        [('mime_no_arms', 2), ('free_pass', 2)],
        reason: 'ordre du catalogue ; l\'autre équipe n\'a rien dépensé');
    playTurn(p);
    expect(p.getCurrentTeam()!.id, first);
    expect(left(p, 'free_pass'), 1,
        reason: 'une dépensée en M1, pour la partie');
  });

  test(
      'continuation : les règles de N+1 s\'appliquent tout de suite, le temps '
      'reporté reste exact, le ×2 dépensé vit jusqu\'à la fin du tour, rien ne '
      's\'y allume', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        drawCount: 0,
        modifiers: {
          'double_points': cartridge(2),
          'plus_10s': cartridge(2),
          'reversed': ModifierSetting(
              active: true, rounds: const {2}, mode: ModifierMode.always),
          'no_pass': ModifierSetting(
              active: true, rounds: const {1}, mode: ModifierMode.always),
        },
      ),
    );
    final team = p.getCurrentTeam()!.id;
    expect(p.passBlocked, isTrue);
    p.toggleBonus('double_points');
    p.startTurn();
    p.startTurnTimer();
    for (var i = 0; i < 4; i++) {
      p.markWordAsGuessed();
    }
    final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
    p.savePreValidationState(guessed);
    p.validateWords(guessed);
    final carried = p.game.turnBonusTime!;
    p.nextRound();

    expect(p.getCurrentTeam()!.id, team);
    expect(p.isContinuation, isTrue);
    // Règles de M2, plus celles de M1.
    expect(p.isWordReversed, isTrue);
    expect(p.passBlocked, isFalse);
    expect(p.currentTeamModifiers.map((m) => m.catalogId), ['reversed']);
    // Le temps n'a pas bougé, le ×2 dépensé tient, le +10 s ne s'allume pas.
    expect(p.turnTime.total, carried);
    expect(p.isDoublePointsOn, isTrue);
    expect(p.reserve, isEmpty);
    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, carried);
    expect(p.game.fiesta!.turn.charges.containsKey('plus_10s'), isFalse);

    // Même lecture après un kill.
    final reloaded = await reload();
    expect(reloaded.isWordReversed, isTrue);
    expect(reloaded.isDoublePointsOn, isTrue);
  });

  test(
      'continuation qui vide à elle seule le pool de N+1 : la manche suivante '
      'démarre bien, aucune règle de N ne traîne', () async {
    final p = await givenProvider(['Ana', 'Bob'], wordsEach: 1);
    await p.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        drawCount: 0,
        modifiers: {
          'reversed': ModifierSetting(
              active: true, rounds: const {2}, mode: ModifierMode.always),
          'no_pass': ModifierSetting(
              active: true, rounds: const {3}, mode: ModifierMode.always),
        },
      ),
    );
    playTurn(p, 99);
    p.nextRound();
    playTurn(p, 99);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.game.currentRound, 2);
    p.nextRound();
    expect(p.game.currentRound, 3);
    expect(p.currentTeamModifiers.map((m) => m.catalogId), ['no_pass']);
    playTurn(p, 99);
    expect(p.game.currentScreen, AppConstants.screenResults);
  });

  test('une partie sans cartouche nulle part reste normale', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(
      fiesta: FiestaRules(mode: FiestaMode.custom, drawCount: 0, modifiers: {
        'one_answer': ModifierSetting(
            active: true, rounds: const {1, 2, 3}, mode: ModifierMode.always),
      }),
    );
    expect(p.reserve, isEmpty);
    finishRoundWithGap(p);
    p.nextRound();
    expect(p.game.fiesta!.earned, isEmpty);
    expect(p.isOneAnswer, isTrue);
  });

  test('récap : le coup de pouce relu de l\'état, sans rattrapage ni choix',
      () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: cartridges(['plus_10s']));
    final (trailing, _) = finishRoundWithGap(p);
    p.nextRound();
    final line = p.modifierRecap
        .singleWhere((l) => l.title == 'Coup de pouce à l\'équipe menée');
    expect(line.detail,
        '${p.getTeamById(trailing)!.name} reçoit Bonus de 10 s (M2)');
  });
}
