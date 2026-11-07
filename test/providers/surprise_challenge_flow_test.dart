import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/challenge_plan.dart';
import 'package:guess_it_all_mobile/models/fiesta/ensemble_validation.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/surprise_challenge.dart';
import 'package:guess_it_all_mobile/models/game_state.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Une partie dont le programme de défis vérifie [matches].
String gameIdWhere(bool Function(Map<int, SurpriseChallenge>) matches) {
  for (var i = 0;; i++) {
    final id = 'game-$i';
    if (matches(drawChallengeSchedule(id))) return id;
  }
}

Future<GameProvider> givenGame(String gameId, {bool challenges = true}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final p = GameProvider();
  await pumpEventQueue();
  p.updateSettings(numberOfTeams: 2);
  final ids = <String>[];
  for (var i = 0; i < 6; i++) {
    final id = (p.addPlayer('J$i')['player'] as dynamic).id as String;
    p.updatePlayerWords(id, [for (var w = 0; w < 2; w++) 'm$i-$w']);
    ids.add(id);
  }
  p.createTeams();
  for (var i = 0; i < 6; i++) {
    p.movePlayerToTeam(ids[i], p.teams[i < 3 ? 0 : 1].id);
  }
  await p.startGame(fiesta: FiestaRules(challenges: challenges));

  // Partie à l'identifiant choisi : le programme en dépend.
  p.goToScreen(AppConstants.screenVerification);
  p.savePreValidationState(const []);
  p.game.preValidationSnapshot!['game'] = {
    ...p.game.preValidationSnapshot!['game'] as Map<String, dynamic>,
    'gameId': gameId,
  };
  p.restorePreValidationState();
  p.goToScreen(AppConstants.screenGame);
  return p;
}

/// Vide la manche : le joueur qui joue trouve tout. Finit sur la transition.
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

int earnedCount(GameProvider p) => p.game.fiesta!.earned.length;

void main() {
  group('enchaînement', () {
    test('réglage coupé : jamais de défi', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)),
          challenges: false);
      finishRound(p);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(p.currentChallenge, isNull);
    });

    test('un défi après M1 seulement : M1 → défi → avant-tour, puis plus rien',
        () async {
      final p = await givenGame(
          gameIdWhere((s) => s.length == 1 && s.containsKey(1)));
      finishRound(p);
      expect(p.game.currentScreen, AppConstants.screenTransition);
      p.nextRound();
      expect(p.game.currentRound, 2);
      expect(p.game.currentScreen, AppConstants.screenChallenge);
      expect(p.currentChallenge?.finishedRound, 1);

      p.finishChallenge();
      expect(p.game.currentScreen, AppConstants.screenGame);
      finishRound(p);
      p.nextRound();
      expect(p.game.currentRound, 3);
      expect(p.game.currentScreen, AppConstants.screenGame);
    });

    test('un défi après M2 seulement : rien après M1', () async {
      final p = await givenGame(
          gameIdWhere((s) => s.length == 1 && s.containsKey(2)));
      finishRound(p);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenGame);
      finishRound(p);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenChallenge);
      expect(p.currentChallenge?.finishedRound, 2);
    });

    test('deux défis : après M1 et après M2', () async {
      final p = await givenGame(gameIdWhere((s) => s.length == 2));
      finishRound(p);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenChallenge);
      p.finishChallenge();
      finishRound(p);
      p.nextRound();
      expect(p.game.currentScreen, AppConstants.screenChallenge);
      expect(p.currentChallenge?.finishedRound, 2);
    });
  });

  group('le gain', () {
    test('la cartouche tirée va au gagnant, une seule fois', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final plan = p.currentChallenge!;
      final before = earnedCount(p);

      p.finishChallenge(winnerTeamId: plan.second.teamId);
      p.finishChallenge(winnerTeamId: plan.second.teamId);

      final earned = p.game.fiesta!.earned;
      expect(earned.length, before + 1);
      expect(earned.last.catalogId, plan.second.prizeId);
      expect(earned.last.teamId, plan.second.teamId);
      expect(earned.last.round, 2);
    });

    test('« Passer » : pas de cartouche', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final before = earnedCount(p);
      p.finishChallenge();
      expect(earnedCount(p), before);
      expect(p.game.fiesta!.challenges.single.finishedRound, 1);
    });
  });

  group('robustesse', () {
    test('app tuée pendant le défi : le même défi revient, rien de donné',
        () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final plan = p.currentChallenge!;
      final before = earnedCount(p);

      final reloaded = GameProvider();
      await pumpEventQueue(times: 200);

      expect(reloaded.game.currentScreen, AppConstants.screenChallenge);
      expect(earnedCount(reloaded), before);
      final again = reloaded.currentChallenge!;
      expect(again.challenge, plan.challenge);
      expect(again.word, plan.word);
      expect(again.first.playerId, plan.first.playerId);
      expect(again.second.playerId, plan.second.playerId);
      expect(again.first.prizeId, plan.first.prizeId);
      expect(again.second.prizeId, plan.second.prizeId);
    });

    test('app tuée après le défi : pas rejoué, cartouche gardée', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      p.finishChallenge(winnerTeamId: p.currentChallenge!.first.teamId);
      final after = earnedCount(p);

      final reloaded = GameProvider();
      await pumpEventQueue(times: 200);

      expect(reloaded.game.currentScreen, AppConstants.screenGame);
      expect(earnedCount(reloaded), after);
      expect(reloaded.game.fiesta!.challenges.length, 1);
    });

    test('retour à la vérification et revalidation : ni doublon, ni rejeu',
        () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final plan = p.currentChallenge!;
      p.finishChallenge(winnerTeamId: plan.first.teamId);
      final after = p.game.fiesta!.earned.toList();

      p.restorePreValidationState();
      expect(p.game.currentScreen, AppConstants.screenVerification);
      expect(p.game.currentRound, 1);
      expect(p.game.fiesta!.challenges.length, 1, reason: 'défi retenu');

      final words = List<String>.from(p.game.wordsGuessedThisTurn);
      p.savePreValidationState(words);
      p.validateWords(words);
      p.nextRound();

      expect(p.game.currentRound, 2);
      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(p.game.fiesta!.earned.length, after.length);
      expect(
        p.game.fiesta!.earned
            .where((e) =>
                e.catalogId == plan.first.prizeId &&
                e.teamId == plan.first.teamId)
            .length,
        after
            .where((e) =>
                e.catalogId == plan.first.prizeId &&
                e.teamId == plan.first.teamId)
            .length,
      );
    });

    test('un défi passé puis retour arrière n\'est pas rejoué', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final before = earnedCount(p);
      p.finishChallenge();

      p.restorePreValidationState();
      final words = List<String>.from(p.game.wordsGuessedThisTurn);
      p.savePreValidationState(words);
      p.validateWords(words);
      p.nextRound();

      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(earnedCount(p), before);
    });

    test('correction qui rouvre la manche : cartouche gardée, pas de rejeu',
        () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      final plan = p.currentChallenge!;
      p.finishChallenge(winnerTeamId: plan.first.teamId);
      final prizes = p.game.fiesta!.challenges.map((c) => c.prize).toList();

      p.restorePreValidationState();
      final words = List<String>.from(p.game.wordsGuessedThisTurn);
      final corrected = words.sublist(1);
      p.savePreValidationState(corrected);
      p.validateWords(corrected);

      expect(p.game.currentRound, 1, reason: 'un mot revient dans la manche');
      expect(p.game.currentScreen, AppConstants.screenGame);
      finishRound(p);
      p.nextRound();

      expect(p.game.currentRound, 2);
      expect(p.game.currentScreen, AppConstants.screenGame);
      expect(p.game.fiesta!.challenges.map((c) => c.prize).toList(), prizes);
      expect(
        p.game.fiesta!.cartridgesOwned(plan.first.prizeId, plan.first.teamId),
        greaterThanOrEqualTo(1),
      );
    });

    test('retour arrière sur un tour APRÈS le défi : pas de doublon', () async {
      final p = await givenGame(gameIdWhere((s) => s.containsKey(1)));
      finishRound(p);
      p.nextRound();
      p.finishChallenge(winnerTeamId: p.currentChallenge!.first.teamId);
      final after = earnedCount(p);

      p.startTurn();
      p.startTurnTimer();
      p.endTurn();
      p.savePreValidationState(const []);
      p.validateWords(const []);
      p.restorePreValidationState();

      expect(earnedCount(p), after);
      expect(p.game.fiesta!.challenges.length, 1);
    });
  });

  group('planChallenge', () {
    FiestaRules everythingAlways() => FiestaRules(
          challenges: true,
          modifiers: {
            for (final def in kModifierCatalog)
              def.id: const ModifierSetting(always: true),
          },
        );

    ChallengePlan? plan(
      FiestaState fiesta, {
      required String gameId,
      List<String> words = const ['Lion'],
      int finishedRound = 1,
    }) =>
        planChallenge(
          fiesta: fiesta,
          gameId: gameId,
          finishedRound: finishedRound,
          scores: const {'a': 9, 'b': 3, 'c': 5},
          rosters: const {
            'a': ['a1', 'a2'],
            'b': ['b1', 'b2', 'b3'],
            'c': ['c1', 'c2'],
          },
          turns: const [
            TurnPace(playerId: 'b1', words: 5, seconds: 30),
            TurnPace(playerId: 'b2', words: 2, seconds: 30),
            TurnPace(playerId: 'c1', words: 1, seconds: 30),
            TurnPace(playerId: 'c2', words: 4, seconds: 30),
            TurnPace(playerId: 'a1', words: 0, seconds: 30),
          ],
          guessedWords: words,
          blockableTeamIds: const {'b'},
        );

    test('les 2 équipes les plus en retard, leur joueur le moins rapide', () {
      final id = gameIdWhere((s) => s.containsKey(1));
      final p =
          plan(FiestaState(rules: FiestaRules(challenges: true)), gameId: id)!;
      expect(p.first.teamId, 'b');
      expect(p.first.playerId, 'b2');
      expect(p.second.teamId, 'c');
      expect(p.second.playerId, 'c1');
      expect(modifierById(p.first.prizeId), isNotNull);
      expect(modifierById(p.second.prizeId), isNotNull);
    });

    test('récompense : Mot compte double sort 3 fois moins qu\'une autre', () {
      final counts = <String, int>{};
      for (var i = 0; i < 6000; i++) {
        final id = 'g$i';
        if (!drawChallengeSchedule(id).containsKey(1)) continue;
        final p = plan(FiestaState(rules: FiestaRules(challenges: true)),
            gameId: id)!;
        counts.update(p.second.prizeId, (n) => n + 1, ifAbsent: () => 1);
      }
      final others = counts.entries.where((e) => e.key != 'double_points');
      final mean = others.fold<int>(0, (n, e) => n + e.value) / others.length;
      // Attendu : 1/3. Graines fixes, donc résultat stable.
      expect(counts['double_points']! / mean, inInclusiveRange(0.2, 0.5));
    });

    test('vivier vide : pas de défi', () {
      final id = gameIdWhere((s) => s.containsKey(1));
      expect(plan(FiestaState(rules: everythingAlways()), gameId: id), isNull);
    });

    test('téléphone arabe sans mot deviné : pas de défi', () {
      final id = gameIdWhere((s) => s[1] == SurpriseChallenge.mimeRelay);
      final rules = FiestaState(rules: FiestaRules(challenges: true));
      expect(plan(rules, gameId: id, words: const []), isNull);
      expect(plan(rules, gameId: id)?.word, 'Lion');
    });

    test('un autre défi sans mot deviné a quand même lieu', () {
      final id = gameIdWhere(
          (s) => s.containsKey(1) && s[1] != SurpriseChallenge.mimeRelay);
      expect(
        plan(FiestaState(rules: FiestaRules(challenges: true)),
            gameId: id, words: const []),
        isNotNull,
      );
    });

    test('défi déjà terminé : plus de plan', () {
      final id = gameIdWhere((s) => s.containsKey(1));
      expect(
        plan(
          FiestaState(
            rules: FiestaRules(challenges: true),
            challenges: const [ChallengeResult(finishedRound: 1)],
          ),
          gameId: id,
        ),
        isNull,
      );
    });
  });

  group('persistance', () {
    test('FiestaRules : clé absente = coupé, même format, relu', () {
      expect(FiestaRules.format, 4);
      final off = FiestaRules();
      expect(off.toJson().containsKey('challenges'), isFalse);
      expect(FiestaRules.tryFromJson(off.toJson())!.challenges, isFalse);
      final on = FiestaRules(challenges: true);
      expect(FiestaRules.tryFromJson(on.toJson())!.challenges, isTrue);
      expect(
        FiestaRules.tryFromJson({...on.toJson(), 'challenges': 'oui'}),
        isNull,
      );
    });

    test('FiestaState : résultats relus, clé absente = aucun', () {
      expect(
        FiestaState(rules: FiestaRules()).toJson().containsKey('challenges'),
        isFalse,
      );
      final state = FiestaState(
        rules: FiestaRules(challenges: true),
        challenges: const [
          ChallengeResult(finishedRound: 1),
          ChallengeResult(
            finishedRound: 2,
            prize:
                EarnedCartridge(catalogId: 'plus_10s', teamId: 't', round: 3),
          ),
        ],
      );
      final read = FiestaState.tryFromJson(state.toJson())!;
      expect(read.challenges.length, 2);
      expect(read.challenges.first.prize, isNull);
      expect(read.challenges.last.finishedRound, 2);
      expect(read.challenges.last.prize!.catalogId, 'plus_10s');
    });

    test('une partie relue sans la clé reste jouable', () {
      final json = GameState(
        fiesta: FiestaState(rules: FiestaRules(drawCount: 1)),
      ).toJson();
      expect(GameState.fromJson(json).fiesta!.challenges, isEmpty);
    });
  });

  group('validation', () {
    test('le réglage seul suffit à enregistrer', () {
      expect(hasActiveSetting(FiestaRules()), isFalse);
      expect(hasActiveSetting(FiestaRules(challenges: true)), isTrue);
      expect(
        validateEnsemble(FiestaRules(ensembleName: 'A', challenges: true)),
        isEmpty,
      );
    });

    test('il distingue deux ensembles, sans changer les clés existantes', () {
      final base = FiestaRules(allCount: 2);
      expect(settingsKey(base),
          isNot(settingsKey(base.copyWith(challenges: true))));
      expect(settingsKey(base), isNot(contains('challenges')));
    });
  });
}
