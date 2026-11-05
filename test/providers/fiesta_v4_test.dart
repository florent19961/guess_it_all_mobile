import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_state.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// 2 équipes : [a] joueurs, [b] joueurs ; l'ordre de jeu et les rotations sont
/// fixés (équipe 0 d'abord, joueurs dans l'ordre).
Future<GameProvider> givenGame(
  FiestaRules rules, {
  int a = 3,
  int b = 3,
  int wordsEach = 4,
}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final p = GameProvider();
  await pumpEventQueue();
  p.updateSettings(numberOfTeams: 2);
  final ids = <String>[];
  for (var i = 0; i < a + b; i++) {
    final id = (p.addPlayer('J$i')['player'] as dynamic).id as String;
    p.updatePlayerWords(id, [for (var w = 0; w < wordsEach; w++) 'm$i-$w']);
    ids.add(id);
  }
  p.createTeams();
  for (var i = 0; i < a + b; i++) {
    p.movePlayerToTeam(ids[i], p.teams[i < a ? 0 : 1].id);
  }
  await p.startGame(fiesta: rules);
  return p;
}

/// Fixe l'ordre : équipe 0 puis 1, joueurs dans l'ordre, équipe [first] joue.
void orderFixed(GameProvider p) {
  final json = p.game.toJson();
  json['teamPlayOrder'] = [0, 1];
  json['playerOrderByTeam'] = {
    for (final t in p.teams)
      t.id: List<int>.generate(t.playerIds.length, (i) => i),
  };
  json['currentTeamIndex'] = 0;
  json['currentPlayerIndexInTeam'] = 0;
  json['currentTurnIndex'] = 0;
  restore(p, json);
}

void restore(GameProvider p, Map<String, dynamic> gameJson) {
  // Passe par le retour arrière pour réinjecter un état arbitraire.
  p.goToScreen(AppConstants.screenVerification);
  p.savePreValidationState(const []);
  final snapshot = Map<String, dynamic>.from(p.game.preValidationSnapshot!);
  snapshot['game'] = gameJson;
  p.game.preValidationSnapshot!['game'] = gameJson;
  p.restorePreValidationState();
  p.goToScreen(AppConstants.screenGame);
}

String? player(GameProvider p) => p.getCurrentPlayer()?.name;
String team(GameProvider p) => p.getCurrentTeam()!.id;
String other(GameProvider p) => p.teams.firstWhere((t) => t.id != team(p)).id;

/// Un tour complet, sans mot trouvé, depuis l'avant-tour.
void playEmptyTurn(GameProvider p) {
  p.startTurn();
  p.startTurnTimer();
  p.endTurn();
  p.savePreValidationState(const []);
  p.validateWords(const []);
}

/// Vide la manche : le joueur qui joue trouve tous les mots.
void finishRound(GameProvider p) {
  p.startTurn();
  p.startTurnTimer();
  while (p.game.currentWord != null) {
    p.markWordAsGuessed();
  }
  final guessed = List<String>.from(p.game.wordsGuessedThisTurn);
  p.savePreValidationState(guessed);
  p.validateWords(guessed);
}

FiestaRules stock(Map<String, int> charges, {int allCount = 0}) => FiestaRules(
      allCount: allCount,
      modifiers: {
        for (final e in charges.entries)
          e.key: ModifierSetting(charges: e.value),
      },
    );

int left(GameProvider p, String id) =>
    p.reserve.where((c) => c.catalogId == id).firstOrNull?.left ?? 0;

void main() {
  group('Interdit de faire deviner : le piège', () {
    Future<GameProvider> blocked({int b = 3, Map<String, int>? more}) async {
      final p = await givenGame(
          stock({'block_giver': 1, 'plus_10s': 1, ...?more}),
          a: 3,
          b: b);
      orderFixed(p);
      return p;
    }

    /// J0 (équipe 0) nomme le joueur d'index [slot] de l'équipe 1, joue son
    /// tour, et c'est à l'équipe 1.
    void send(GameProvider p, int slot) {
      final target = p.teams[1];
      expect(
          p.inflictMalus('block_giver', target.id,
              playerId: target.playerIds[slot]),
          isNull);
      playEmptyTurn(p);
    }

    test('rotation : Alice, ~~Bob~~, Frank, Alice, Bob, Frank', () async {
      final p = await blocked();
      playEmptyTurn(p); // J0
      expect(player(p), 'J3');
      playEmptyTurn(p); // J3
      // L'équipe 0 (J1) nomme J4 de l'équipe 1 (prochain slot de l'équipe 1).
      send(p, 1);
      expect(player(p), 'J4');
      final seq = <String>[];
      // Le piège au départ.
      p.startTurn();
      p.startTurnTimer();
      expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
      p.confirmGiverBlock();
      for (var i = 0; i < 4; i++) {
        seq.add(player(p)!);
        playEmptyTurn(p); // équipe 1
        playEmptyTurn(p); // équipe 0
      }
      expect(seq, ['J5', 'J3', 'J4', 'J5']);
    });

    test('équipe de 2 : Alice joue deux fois de suite', () async {
      final p = await blocked(b: 2);
      playEmptyTurn(p); // J0
      expect(player(p), 'J3');
      playEmptyTurn(p); // J3
      send(p, 1); // J1 nomme J4
      expect(player(p), 'J4');
      p.startTurn();
      p.startTurnTimer();
      p.confirmGiverBlock();
      expect(player(p), 'J3', reason: 'J3 rejoue, deux tours d\'affilée');
      playEmptyTurn(p);
      playEmptyTurn(p);
      expect(player(p), 'J4');
    });

    test('il saute son prochain VRAI tour, même si la manche finit avant',
        () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[1]);
      // L'équipe 0 finit la manche : J4 n'a pas encore joué, ni J3.
      finishRound(p);
      p.nextRound();
      expect(p.isContinuation, isTrue);
      playEmptyTurn(p); // continuation de J0
      expect(player(p), 'J3');
      playEmptyTurn(p); // J3 joue normalement
      playEmptyTurn(p); // J1
      expect(player(p), 'J4');
      p.startTurn();
      p.startTurnTimer();
      expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
    });

    test(
        'parcours : avant-tour sans trace, chrono non démarré, rien consommé '
        'avant « Suivant », app tuée = même phrase', () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);
      expect(player(p), 'J3');
      expect(p.receivedThisTurn, isEmpty, reason: 'aucune trace');
      expect(p.currentTeamModifiers, isEmpty);

      p.toggleBonus('plus_10s');
      p.startTurn();
      expect(p.game.currentScreen, AppConstants.screenCountdown);
      p.startTurnTimer();
      expect(p.game.currentScreen, AppConstants.screenGiverBlocked);
      expect(p.game.turnEndTimestamp, isNull, reason: 'chrono non démarré');
      expect(p.isBonusArmed('plus_10s'), isTrue, reason: 'rien de consommé');
      final phrase = p.giverBlockScreen!.phrase;
      expect(phrase, contains('J3'));
      expect(phrase, contains('J0'), reason: 'le JOUEUR qui a bloqué');
      expect(p.giverBlockScreen!.nextPlayer, 'J4');

      // App tuée : l'état relu remontre la phrase.
      final relu = GameState.fromJson(p.game.toJson());
      expect(relu.currentScreen, AppConstants.screenGiverBlocked);
      expect(
          relu.fiesta!.active.any((m) => m.catalogId == 'block_giver'), isTrue);
      expect(p.giverBlockScreen!.phrase, phrase);
    });

    test(
        'tout ce qu\'il avait préparé est annulé, cartouches rendues ; le lien '
        'remet ce qui reste possible en un toucher', () async {
      final p = await givenGame(stock(
          {'block_giver': 1, 'plus_10s': 1, 'reversed': 1, 'no_pass': 1}));
      orderFixed(p);
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);

      p.toggleBonus('plus_10s');
      p.inflictMalus('reversed', p.teams[0].id);
      expect(left(p, 'reversed'), 0);
      p.startTurn();
      p.startTurnTimer();
      p.confirmGiverBlock();

      expect(player(p), 'J4');
      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(p.bonusesThisTurn, isEmpty);
      expect(left(p, 'plus_10s'), 1);
      expect(left(p, 'reversed'), 1, reason: 'cartouche rendue');
      expect(p.sentThisTurn, isEmpty);
      expect(p.replacedPlayer?.name, 'J3');
      expect(p.game.fiesta!.active.any((m) => m.catalogId == 'block_giver'),
          isFalse);

      p.reuseReplacedChoices();
      expect(p.bonusesThisTurn, ['plus_10s']);
      expect(p.sentThisTurn.single.catalogId, 'reversed');
      expect(left(p, 'reversed'), 0);
      expect(p.replacedPlayer, isNull, reason: 'en un toucher');
    });

    test('rien préparé : pas de lien', () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);
      p.startTurn();
      p.startTurnTimer();
      p.confirmGiverBlock();
      expect(p.replacedPlayer, isNull);
    });

    test('le remplaçant qui finit la manche reprend sur le temps reporté',
        () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);
      p.startTurn();
      p.startTurnTimer();
      p.confirmGiverBlock();
      expect(player(p), 'J4');
      finishRound(p);
      p.nextRound();
      expect(player(p), 'J4');
      expect(p.isContinuation, isTrue);
      expect(p.game.turnBonusTime, isNotNull);
    });

    test('retour arrière : tout revient, sans doublon', () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);
      p.startTurn();
      p.startTurnTimer();
      p.confirmGiverBlock();
      expect(p.game.fiesta!.skips[target.id], 1);

      p.restorePreValidationState();
      expect(p.game.currentScreen, AppConstants.screenVerification);
      expect(p.game.fiesta!.active.where((m) => m.catalogId == 'block_giver'),
          hasLength(1));
      expect(p.game.fiesta!.skips, isEmpty);
    });

    test('un seul blocage de chaque type en attente par équipe', () async {
      final p = await blocked(more: {'block_giver': 2});
      final target = p.teams[1];
      expect(
          p.inflictMalus('block_giver', target.id,
              playerId: target.playerIds[0]),
          isNull);
      expect(
          p.inflictMalus('block_giver', target.id,
              playerId: target.playerIds[1]),
          startsWith('Impossible'));
      expect(left(p, 'block_giver'), 1, reason: 'rien consommé');
    });

    test('un blocage exige un joueur de l\'équipe visée', () async {
      final p = await blocked();
      p.inflictMalus('block_giver', p.teams[1].id);
      p.inflictMalus('block_giver', p.teams[1].id,
          playerId: p.teams[0].playerIds[0]);
      expect(left(p, 'block_giver'), 1);
    });

    test('un blocage qui attend n\'est plus annulable au tour suivant',
        () async {
      final p = await blocked();
      final target = p.teams[1];
      p.inflictMalus('block_giver', target.id, playerId: target.playerIds[1]);
      expect(p.sentThisTurn, hasLength(1));
      playEmptyTurn(p); // J0
      playEmptyTurn(p); // J3 : J4 n'a pas joué, il attend
      expect(team(p), p.teams[0].id);
      expect(p.sentThisTurn, isEmpty);
    });
  });

  group('Bloquer un devineur', () {
    Future<GameProvider> given({int b = 3}) async {
      final p = await givenGame(stock({'block_guesser': 1}), b: b);
      orderFixed(p);
      return p;
    }

    test('équipe de 2 joueurs : grisée, aucune cible', () async {
      final p = await given(b: 2);
      expect(p.targetsFor('block_guesser'), isEmpty);
      expect(p.reserve.single.blockedReason, isNotNull);
    });

    test('joueur nommé à l\'envoi ; au tour concerné, il ne répond pas',
        () async {
      final p = await given();
      final target = p.teams[1];
      p.inflictMalus('block_guesser', target.id, playerId: target.playerIds[1]);
      playEmptyTurn(p);
      expect(player(p), 'J3');
      expect(p.blockedGuesser?.name, 'J4');
      playEmptyTurn(p);
      playEmptyTurn(p);
      expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null), isEmpty,
          reason: 'consommé à la fin de ce tour');
    });

    test('s\'il fait deviner ce tour-là, le blocage attend', () async {
      final p = await given();
      final target = p.teams[1];
      p.inflictMalus('block_guesser', target.id, playerId: target.playerIds[0]);
      playEmptyTurn(p);
      expect(player(p), 'J3');
      expect(p.blockedGuesser, isNull);
      expect(p.currentTeamModifiers, isEmpty);
      playEmptyTurn(p);
      expect(p.game.fiesta!.active.where((m) => m.fromTeamId != null),
          hasLength(1));
      playEmptyTurn(p); // J1
      expect(player(p), 'J4');
      expect(p.blockedGuesser?.name, 'J3');
    });
  });

  group('Cartouches et passage de manche', () {
    test('compteur : donné à chaque équipe, gardé jusqu\'à la fin', () async {
      final p = await givenGame(stock({'plus_10s': 2}));
      expect(left(p, 'plus_10s'), 2);
      finishRound(p);
      p.nextRound();
      expect(left(p, 'plus_10s'), 2);
    });

    test('allCount : dès M1, puis à chaque manche, gardées', () async {
      final p = await givenGame(FiestaRules(allCount: 2));
      expect(p.game.fiesta!.earned.where((e) => e.round == 1), hasLength(4));
      finishRound(p);
      p.nextRound();
      expect(p.game.fiesta!.earned.where((e) => e.round == 2), hasLength(4));
      expect(p.game.fiesta!.earned.where((e) => e.round == 1), hasLength(4));
    });

    test(
        'pas de doublon ni de perte après retour arrière, correction, kill '
        'sur l\'animation', () async {
      final p = await givenGame(FiestaRules(trailingCount: 2));
      finishRound(p);
      expect(p.game.currentScreen, AppConstants.screenTransition);
      expect(p.game.fiesta!.earned, isEmpty, reason: 'seul nextRound écrit');

      p.nextRound();
      final after = p.game.fiesta!.earned.map((e) => e.catalogId).toList();
      expect(after, hasLength(2));

      // Retour arrière depuis l'avant-tour de N+1.
      expect(p.canGoBackToVerification, isTrue);
      p.restorePreValidationState();
      expect(p.game.fiesta!.earned, isEmpty);
      expect(p.game.currentScreen, AppConstants.screenVerification);

      // Revalidation identique : mêmes cartouches, une seule fois.
      final words = p.game.restoredValidatedWords!;
      p.clearRestoredValidatedWords();
      p.savePreValidationState(words);
      p.validateWords(words);
      p.nextRound();
      expect(p.game.fiesta!.earned.map((e) => e.catalogId).toList(), after);
      p.nextRound(); // double appel : sans effet
      expect(p.game.currentRound, 2);
      expect(p.game.fiesta!.earned, hasLength(2));
    });

    test('M3 : écran fixe, archivage et résultats à « Voir les résultats »',
        () async {
      final p = await givenGame(FiestaRules(allCount: 1));
      finishRound(p);
      p.nextRound();
      playEmptyTurn(p); // continuation à 0 s ou non : la manche reste ouverte
      finishRound(p);
      p.nextRound();
      playEmptyTurn(p);
      finishRound(p);
      expect(p.game.currentRound, 3);
      expect(p.game.currentScreen, AppConstants.screenTransition);
      expect(p.canGoBackToVerification, isTrue);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenResults);
    });

    test('Classique : passage de manche identique, M3 compris', () async {
      await givenPrefs();
      givenFakePlatformPlugins();
      final p = GameProvider();
      await pumpEventQueue();
      p.updateSettings(numberOfTeams: 2);
      for (var i = 0; i < 4; i++) {
        final id = (p.addPlayer('J$i')['player'] as dynamic).id as String;
        p.updatePlayerWords(id, ['m$i']);
      }
      p.createTeams();
      p.randomizeTeams();
      await p.startGame();
      finishRound(p);
      expect(p.game.currentScreen, AppConstants.screenTransition);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(p.game.currentRound, 2);
    });
  });

  group('Conflits au tour de la cible', () {
    test('cartouche identique à la règle de manche : grisée, garde son stock',
        () async {
      final p = await givenGame(FiestaRules(drawCount: 1, modifiers: const {
        'reversed': ModifierSetting(draw: true, charges: 1),
      }));
      expect(p.reserve.single.usable, isFalse);
      expect(left(p, 'reversed'), 1);
    });

    test('Autre langue envoyé en M2 à une cible qui rejoue en M3 : RENDU',
        () async {
      final p = await givenGame(stock({'other_language': 1}));
      orderFixed(p);
      finishRound(p);
      p.nextRound();
      // Continuation de l'équipe 0 en M2 : elle envoie, puis vide la manche.
      expect(p.isContinuation, isTrue);
      final me = team(p);
      p.inflictMalus('other_language', other(p));
      expect(left(p, 'other_language'), 0);
      finishRound(p);
      p.nextRound();
      expect(p.game.currentRound, 3);
      expect(team(p), me);
      final fiesta = p.game.fiesta!;
      expect(fiesta.active.where((m) => m.fromTeamId != null), isEmpty);
      expect(fiesta.cartridgesLeft('other_language', me), 1, reason: 'rendue');
    });
  });

  test('rotation sans blocage : inchangée', () async {
    final p = await givenGame(FiestaRules(allCount: 0, trailingCount: 1));
    orderFixed(p);
    final seq = <String>[];
    for (var i = 0; i < 6; i++) {
      seq.add(player(p)!);
      playEmptyTurn(p);
    }
    expect(seq, ['J0', 'J3', 'J1', 'J4', 'J2', 'J5']);
  });
}
