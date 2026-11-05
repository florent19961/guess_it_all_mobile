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

ModifierSetting cartridge(int charges) => ModifierSetting(charges: charges);

/// [ids] en cartouche à [charges] pour la partie.
FiestaRules cartridges(List<String> ids,
        {int charges = 0, bool boost = false}) =>
    FiestaRules(
      drawCount: 0,
      trailingCount: boost ? 1 : 0,
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
      'reporté reste exact, le ×2 dépensé vit jusqu\'à la fin du tour et ne se '
      'rallume pas, le +10 s s\'y ajoute', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(
      fiesta: FiestaRules(
        drawCount: 1,
        modifiers: {
          'double_points': cartridge(2),
          'plus_10s': cartridge(2),
          // Sans candidat avant M3 : la seule règle tombe en M3.
          'draw': const ModifierSetting(draw: true),
        },
      ),
    );
    playTurn(p, 99); // M1
    p.nextRound();
    playTurn(p); // fin de la continuation, l'autre équipe joue
    final team = p.getCurrentTeam()!.id;
    expect(p.currentTeamModifiers, isEmpty);
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
    expect(p.currentTeamModifiers.map((m) => m.catalogId), ['draw']);
    // Le temps n'a pas bougé, le ×2 dépensé tient, le +10 s s'allume.
    expect(p.turnTime.total, carried);
    expect(p.isDoublePointsOn, isTrue);
    expect(
        p.reserve
            .firstWhere((c) => c.catalogId == 'double_points')
            .blockedReason,
        'déjà en cours ce tour');
    p.toggleBonus('plus_10s');
    expect(p.turnTime.total, carried + 10);
    p.toggleBonus('plus_10s');

    // Même lecture après un kill.
    final reloaded = await reload();
    expect(reloaded.currentTeamModifiers.map((m) => m.catalogId), ['draw']);
    expect(reloaded.isDoublePointsOn, isTrue);
  });

  test(
      'continuation qui vide à elle seule le pool de N+1 : la manche suivante '
      'démarre bien, aucune règle de N ne traîne', () async {
    final p = await givenProvider(['Ana', 'Bob'], wordsEach: 1);
    await p.startGame(
      fiesta: FiestaRules(
        drawCount: 1,
        modifiers: {
          'other_language': const ModifierSetting(draw: true),
          'draw': const ModifierSetting(draw: true),
        },
      ),
    );
    playTurn(p, 99);
    p.nextRound();
    expect(p.currentTeamModifiers.map((m) => m.catalogId), ['other_language']);
    playTurn(p, 99);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    expect(p.game.currentRound, 2);
    p.nextRound();
    expect(p.game.currentRound, 3);
    expect(p.currentTeamModifiers.map((m) => m.catalogId), ['draw']);
    playTurn(p, 99);
    expect(p.game.currentScreen, AppConstants.screenTransition);
    p.nextRound();
    expect(p.game.currentScreen, AppConstants.screenResults);
  });

  test('une partie sans cartouche nulle part reste normale', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(
      fiesta: FiestaRules(drawCount: 0, modifiers: {
        'one_answer': const ModifierSetting(always: true),
      }),
    );
    expect(p.reserve, isEmpty);
    finishRoundWithGap(p);
    p.nextRound();
    expect(p.game.fiesta!.earned, isEmpty);
    expect(p.isOneAnswer, isTrue);
  });

  test('récap : les cartouches au hasard relues de l\'état', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: FiestaRules(trailingCount: 1));
    final (trailing, _) = finishRoundWithGap(p);
    p.nextRound();
    final gift = p.game.fiesta!.earned.single;
    final line =
        p.modifierRecap.singleWhere((l) => l.title == 'Cartouches au hasard');
    expect(gift.teamId, trailing);
    expect(line.detail, contains('${p.getTeamById(trailing)!.name} reçoit '));
    expect(line.detail, endsWith('(M2)'));
  });

  test('app tuée après le passage de manche : ni doublon ni perte', () async {
    final p = await givenProvider(['Ana', 'Bob']);
    await p.startGame(fiesta: FiestaRules(trailingCount: 2));
    finishRoundWithGap(p);
    p.nextRound();
    await pumpEventQueue();
    final reloaded = await reload();
    expect(earned(reloaded), earned(p));
    expect(earned(reloaded), hasLength(2));
  });
}
