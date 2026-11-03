import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';

import '../helpers/test_prefs.dart';

/// Un provider prêt à lancer : [names] joueurs en 2 équipes, 1 mot chacun,
/// réglages par défaut (30 s, pénalité de passe 5 s).
Future<GameProvider> givenReadyProvider(
    [List<String> names = const ['Ana', 'Bob']]) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in names) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['mot-$name']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Personnalisé, sans tirage : [fixed] (id → charges) fixés sur la manche 1.
FiestaRules fixedOnRound1(Map<String, int> fixed) => FiestaRules(
      mode: FiestaMode.custom,
      drawCount: 0,
      modifiers: {
        for (final e in fixed.entries)
          e.key: ModifierSetting(
            active: true,
            arrival: ModifierArrival.fixed,
            startRound: 1,
            fixedRound: 1,
            charges: e.value,
          ),
      },
    );

int allotted(GameProvider p) =>
    (p.game.turnEndTimestamp! - p.game.turnStartTimestamp!) ~/ 1000;

void main() {
  test(
      'free_pass ×2 : 0, 0, puis 5 s ; compteur relu après un kill, remis à '
      '0 au tour suivant, rendu par le retour arrière (AC2, AC3, AC4, AC8)',
      () async {
    var provider = await givenReadyProvider();
    await provider.startGame(fiesta: fixedOnRound1({'free_pass': 2}));
    provider.startTurn();
    provider.startTurnTimer();
    // AC3 : la garde porte sur la pénalité EFFECTIVE (2 s affichées suffisent).
    expect(provider.canPassWith(2), isTrue);

    provider.passWord();
    provider.passWord();
    expect(allotted(provider), 30);
    expect(provider.freePassesUsed, 2);
    expect(provider.canPassWith(2), isFalse);

    // App tuée puis rouverte : le compteur est relu de l'état persisté.
    await pumpEventQueue();
    provider = GameProvider();
    await pumpEventQueue();
    expect(provider.freePassesUsed, 2);

    provider.passWord();
    expect(allotted(provider), 25);
    expect(provider.freePassesUsed, 2);

    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);
    expect(provider.freePassesUsed, 0);

    provider.restorePreValidationState();
    expect(provider.freePassesUsed, 2);
  });

  test(
      'no_pass : passWord refusé au niveau du provider, rien ne bouge ; '
      'reversed n\'altère pas le mot du jeu (AC1, AC6)', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
        fiesta: fixedOnRound1({'no_pass': 0, 'reversed': 0}));
    provider.startTurn();
    provider.startTurnTimer();
    final before = provider.game.toJson();

    expect(provider.canPassWith(30), isFalse);
    provider.passWord();

    expect(provider.game.toJson(), before);
    expect(provider.isWordReversed, isTrue);
  });

  test(
      'block_guesser : sans effet à 2 joueurs, sinon jamais celui qui fait '
      'deviner (AC5)', () async {
    var provider = await givenReadyProvider(['A', 'B', 'C', 'D']);
    await provider.startGame(fiesta: fixedOnRound1({'block_guesser': 0}));
    expect(provider.blockableGuessers, isEmpty);
    expect(provider.needsBlockedGuesser, isFalse);

    provider = await givenReadyProvider(['A', 'B', 'C', 'D', 'E', 'F']);
    await provider.startGame(fiesta: fixedOnRound1({'block_guesser': 0}));
    final guesser = provider.getCurrentPlayer()!;
    expect(provider.blockableGuessers.map((p) => p.id),
        isNot(contains(guesser.id)));
    expect(provider.blockableGuessers, hasLength(2));

    provider.setBlockedGuesser(guesser.id); // refusé
    expect(provider.needsBlockedGuesser, isTrue);
    provider.setBlockedGuesser(provider.blockableGuessers.first.id);
    expect(provider.needsBlockedGuesser, isFalse);
  });

  test(
      'Une instance de portée tour franchit la fin de manche avec la '
      'continuation, et tombe à la fin de CE tour', () async {
    var provider = await givenReadyProvider();
    await provider.startGame(fiesta: fixedOnRound1({}));
    final teamId = provider.getCurrentTeam()!.id;

    // Pas encore d'écrivain d'instances de portée tour (2-10) : on en pose une
    // dans l'état persisté, puis on relit la partie.
    await pumpEventQueue();
    final saved = (await StorageService().loadGameState())!;
    (saved['game']['fiesta']['active'] as List).add(ModifierInstance(
      catalogId: 'free_pass',
      scope: ModifierScope.turn,
      target: ModifierTarget.team,
      teamId: teamId,
      charges: 1,
      nature: ModifierNature.bonus,
      round: 1,
    ).toJson());
    await StorageService().saveGameState(saved);
    provider = GameProvider();
    await pumpEventQueue();
    bool held() =>
        provider.game.fiesta!.active.any((m) => m.scope == ModifierScope.turn);
    expect(held(), isTrue);

    // L'équipe fait deviner les 2 mots : fin de manche, elle poursuivra en M2.
    provider.startTurn();
    provider.startTurnTimer();
    provider.markWordAsGuessed();
    provider.markWordAsGuessed();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    provider.nextRound();
    expect(provider.getCurrentTeam()!.id, teamId);
    expect(held(), isTrue);

    // Fin du tour de continuation : consommée.
    provider.startTurn();
    provider.startTurnTimer();
    provider.endTurn();
    provider.savePreValidationState(const []);
    provider.validateWords(const []);
    expect(held(), isFalse);
  });
}
