import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/offers.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Un joueur par équipe, [wordsEach] mots chacun.
Future<GameProvider> givenProvider(List<String> names,
    {required int wordsEach, int? teams}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  provider.updateSettings(numberOfTeams: teams ?? names.length);
  for (final name in names) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(
        id, [for (var i = 0; i < wordsEach; i++) 'mot-$name-$i']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// L'équipe qui joue fait deviner [n] mots, puis le tour est validé (fin de
/// manche si le pool est vide). Rend l'id de l'équipe qui a joué.
String playTurn(GameProvider provider, int n) {
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

/// Personnalisé, 1 parmi 3 allumé, sans tirage : tout le catalogue proposé
/// à l'équipe menée dès M2.
final pickThree = FiestaRules(
  mode: FiestaMode.custom,
  oneOfThree: true,
  drawCount: 0,
  modifiers: {
    for (final def in kModifierCatalog)
      def.id: ModifierSetting(
        active: true,
        arrival: ModifierArrival.offer,
        startRound: 2,
        charges: def.defaultCharges,
      ),
  },
);

List<String> ids(Iterable<ModifierInstance> mods) =>
    mods.map((m) => '${m.catalogId}@${m.round}>${m.teamId}').toList();

void main() {
  test(
      '14–8 : seule l\'équipe à 8 choisit, parmi 3 offres « moyenne », et '
      'nextRound attend son choix (AC1) ; retour arrière + revalidation : '
      'mêmes offres, choix à refaire (AC6) ; le malus choisi frappe le leader '
      'en M2, annoncé à son premier tour (AC4)', () async {
    final provider = await givenProvider(['Ana', 'Bob'], wordsEach: 11);
    await provider.startGame(fiesta: pickThree);
    final leader = playTurn(provider, 14);
    final trailing = playTurn(provider, 8);
    expect(provider.game.currentScreen, AppConstants.screenTransition);

    expect(provider.nextChooserId, trailing);
    expect(provider.offersFor(leader), isEmpty);
    final offers = provider.offersFor(trailing);
    expect(offers.map((m) => m.catalogId).toSet(),
        {'double_points', 'two_words', 'no_pass'});
    expect(
        offers
            .every((m) => kOfferStrength[m.catalogId] == OfferStrength.medium),
        isTrue);

    // La garde est dans le provider : un appel direct ne passe pas.
    provider.nextRound();
    expect(provider.game.currentRound, 1);
    expect(provider.game.currentScreen, AppConstants.screenTransition);

    final noPass = offers.indexWhere((m) => m.catalogId == 'no_pass');
    provider.chooseOffer(trailing, noPass);
    expect(provider.nextChooserId, isNull);

    // AC6 : le choix est postérieur au snapshot, il est à refaire.
    provider.restorePreValidationState();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(provider.nextChooserId, trailing);
    expect(ids(provider.offersFor(trailing)), ids(offers));

    provider.chooseOffer(trailing, noPass);
    provider.nextRound();
    expect(provider.game.currentRound, 2);
    expect(ids(provider.game.fiesta!.active), ['no_pass@2>$leader']);

    // Continuation de l'équipe menée, puis premier tour du leader.
    expect(playTurn(provider, 0), trailing);
    expect(provider.getCurrentTeam()!.id, leader);
    expect(ids(provider.malusToReveal), ['no_pass@2>$leader']);
    expect(provider.passBlocked, isTrue);
  });

  test(
      'app tuée au milieu de la file : le choix fait est gardé, la file '
      'reprend à l\'équipe suivante avec les mêmes offres (AC5)', () async {
    final provider = await givenProvider(['A', 'B', 'C'], wordsEach: 3);
    await provider.startGame(fiesta: pickThree);
    playTurn(provider, 5);
    final second = playTurn(provider, 3);
    final last = playTurn(provider, 1);
    expect(provider.game.currentScreen, AppConstants.screenTransition);

    expect(provider.nextChooserId, last);
    final lastPick = provider.offersFor(last).first;
    provider.chooseOffer(last, 0);
    expect(provider.nextChooserId, second);
    final secondOffers = provider.offersFor(second);
    expect(secondOffers, isNotEmpty);

    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.game.currentScreen, AppConstants.screenTransition);
    expect(reloaded.nextChooserId, second);
    expect(ids(reloaded.offersFor(second)), ids(secondOffers));
    reloaded.nextRound();
    expect(reloaded.game.currentRound, 1);

    reloaded.chooseOffer(second, 0);
    reloaded.nextRound();
    expect(reloaded.game.currentRound, 2);
    expect(ids(reloaded.game.fiesta!.active),
        containsAll(ids([lastPick, secondOffers.first])));
  });

  test(
      '« Bloquer un devineur » choisi pour M2 contre le leader qui a fini M1 : '
      'ni appliqué ni consommé par sa continuation ; annoncé et désigné par '
      'l\'équipe qui l\'a choisi à son premier vrai tour de M2, consommé à '
      'sa fin (epic fix M3)', () async {
    final provider =
        await givenProvider(['A', 'B', 'C', 'D', 'E'], wordsEach: 4, teams: 2);
    await provider.startGame(fiesta: pickThree);
    // Le leader = l'équipe de 3 (seule bloquable) ; il finit la manche, il
    // joue donc la continuation en M2. Écart 16 : force « forte ».
    final leader = provider.teams.firstWhere((t) => t.playerIds.length == 3).id;
    final trailing = provider.teams.firstWhere((t) => t.id != leader).id;
    if (provider.getCurrentTeam()!.id == leader) playTurn(provider, 12);
    playTurn(provider, 2);
    expect(playTurn(provider, 20), leader);
    expect(provider.game.currentScreen, AppConstants.screenTransition);

    expect(provider.offersFor(trailing).map((m) => m.catalogId),
        ['block_guesser']);
    provider.chooseOffer(trailing, 0);
    provider.nextRound();

    // La continuation du leader : le blocage de M2 attend.
    expect(provider.getCurrentTeam()!.id, leader);
    expect(provider.isContinuation, isTrue);
    expect(provider.needsBlockedGuesser, isFalse);
    expect(provider.malusToReveal, isEmpty);
    playTurn(provider, 0);
    expect(ids(provider.game.fiesta!.active), ['block_guesser@2>$leader']);
    playTurn(provider, 0);

    // Premier vrai tour de M2 du leader : annoncé, désigné par la menée.
    expect(provider.getCurrentTeam()!.id, leader);
    expect(ids(provider.malusToReveal), ['block_guesser@2>$leader']);
    expect(provider.needsBlockedGuesser, isTrue);
    expect(provider.blockingTeam!.id, trailing);
    provider.setBlockedGuesser(provider.blockableGuessers.first.id);
    playTurn(provider, 0);
    expect(provider.game.fiesta!.active, isEmpty);
    playTurn(provider, 0);
    expect(provider.getCurrentTeam()!.id, leader);
    expect(provider.needsBlockedGuesser, isFalse);
  });

  test(
      'M2 → M3 : ×2 + blocage de M2 sur le dernier tour, deux tirages en M3. '
      'La continuation garde ×2 et blocage, pas les tirages (2 effets, pas 4) ; '
      'idem après un kill et un retour arrière ; les tirages de M3 commencent '
      'au premier vrai tour (epic fix, Codex MAJOR-1)', () async {
    final provider =
        await givenProvider(['A', 'B', 'C', 'D', 'E'], wordsEach: 4, teams: 2);
    ModifierSetting setting(ModifierArrival arrival, int round) =>
        ModifierSetting(
            active: true,
            arrival: arrival,
            startRound: round,
            fixedRound: round,
            charges: 1);
    await provider.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        oneOfThree: true,
        drawCount: 2,
        modifiers: {
          'block_guesser': setting(ModifierArrival.offer, 2),
          'double_points': setting(ModifierArrival.fixed, 2),
          'no_pass': setting(ModifierArrival.draw, 3),
          'reversed': setting(ModifierArrival.draw, 3),
        },
      ),
    );
    // M1 : le leader (3 joueurs, bloquable) mène de 10+, la menée finit M1.
    final leader = provider.teams.firstWhere((t) => t.playerIds.length == 3).id;
    final trailing = provider.teams.firstWhere((t) => t.id != leader).id;
    if (provider.getCurrentTeam()!.id == trailing) playTurn(provider, 1);
    playTurn(provider, 15);
    expect(playTurn(provider, 20), trailing);
    provider.chooseOffer(trailing, 0);
    provider.nextRound();
    playTurn(provider, 0); // continuation de la menée

    // M2 : premier vrai tour du leader, bloqué et à ×2 ; il finit M2.
    expect(provider.getCurrentTeam()!.id, leader);
    provider.setBlockedGuesser(provider.blockableGuessers.first.id);
    provider.setDoublePoints(true);
    playTurn(provider, 20);
    expect(provider.nextRoundModifiers.map((m) => m.catalogId),
        unorderedEquals(['no_pass', 'reversed']));
    expect(provider.nextChooserId, isNull, reason: 'plafond : rien à offrir');
    provider.nextRound();

    void expectContinuation(GameProvider p) {
      expect(p.getCurrentTeam()!.id, leader);
      expect(p.isContinuation, isTrue);
      expect(ids(p.turnModifiers), ['block_guesser@2>$leader']);
      expect(p.isDoublePointsOn, isTrue);
      expect(p.turnModifiers.length + (p.isDoublePointsOn ? 1 : 0), 2);
      expect(p.blockedGuesser, isNotNull);
      expect(p.needsBlockedGuesser, isFalse);
      expect([p.passBlocked, p.isWordReversed], [false, false]);
      expect(p.malusToReveal, isEmpty);
    }

    expectContinuation(provider);
    await pumpEventQueue();
    final reloaded = GameProvider(); // app tuée avant la continuation
    await pumpEventQueue();
    expectContinuation(reloaded);

    final before = reloaded.teams.firstWhere((t) => t.id == leader).score;
    reloaded.startTurn();
    reloaded.startTurnTimer();
    expectContinuation(reloaded);
    reloaded.markWordAsGuessed();
    reloaded.endTurn();
    final word = List<String>.from(reloaded.game.wordsGuessedThisTurn);
    reloaded.savePreValidationState(word);
    reloaded.validateWords(word);
    // Retour arrière : de nouveau la continuation, puis même revalidation.
    reloaded.restorePreValidationState();
    expectContinuation(reloaded);
    reloaded.savePreValidationState(word);
    reloaded.validateWords(word);
    expect(reloaded.teams.firstWhere((t) => t.id == leader).score, before + 2);

    // Les tirages de M3 commencent au premier vrai tour de chaque équipe ;
    // les effets de M2 sont partis avec la continuation.
    expect(reloaded.getCurrentTeam()!.id, trailing);
    expect(reloaded.passBlocked, isTrue);
    playTurn(reloaded, 0);
    expect(reloaded.getCurrentTeam()!.id, leader);
    expect(reloaded.turnModifiers.map((m) => m.catalogId),
        unorderedEquals(['no_pass', 'reversed']));
    expect(reloaded.malusToReveal.map((m) => m.catalogId),
        unorderedEquals(['no_pass', 'reversed']));
    expect([reloaded.isDoublePointsOn, reloaded.needsBlockedGuesser],
        [false, false]);
    expect(reloaded.game.fiesta!.active.every((m) => m.round == 3), isTrue);
  });

  test(
      'Continuation en chaîne : la continuation M1→M2 vide le pool de M2. Son '
      'tour logique M1 se clôt (×2 dépensé et instances M1 partis), et la '
      'continuation M3 ne porte que le contexte de M2 (blocage M2 annoncé), '
      'kill et retour arrière compris (epic fix r1, Codex MAJOR-1)', () async {
    final provider =
        await givenProvider(['A', 'B', 'C', 'D', 'E'], wordsEach: 4, teams: 2);
    await provider.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        oneOfThree: true,
        drawCount: 1,
        modifiers: {
          'block_guesser': const ModifierSetting(
              active: true,
              arrival: ModifierArrival.offer,
              startRound: 2,
              charges: 0),
          'double_points': const ModifierSetting(
              active: true,
              arrival: ModifierArrival.draw,
              startRound: 1,
              charges: 1),
        },
      ),
    );
    final leader = provider.teams.firstWhere((t) => t.playerIds.length == 3).id;
    final trailing = provider.teams.firstWhere((t) => t.id != leader).id;
    // M1 : le leader finit la manche à ×2. Blocage choisi contre lui pour M2.
    if (provider.getCurrentTeam()!.id == trailing) playTurn(provider, 1);
    provider.setDoublePoints(true);
    expect(playTurn(provider, 20), leader);
    provider.chooseOffer(trailing, 0);
    provider.nextRound();

    // M2 : sa continuation (×2 de M1) vide à elle seule le pool de M2.
    expect(provider.isContinuation, isTrue);
    expect(provider.isDoublePointsOn, isTrue);
    expect(playTurn(provider, 20), leader);
    expect(provider.game.currentRound, 2);
    if (provider.nextChooserId == trailing) provider.chooseOffer(trailing, 0);
    provider.nextRound();

    void expectChained(GameProvider p) {
      expect(p.getCurrentTeam()!.id, leader);
      expect(p.isContinuation, isTrue);
      expect([p.isDoublePointsOn, p.freePassesUsed, p.doublePointsLeft],
          [false, 0, 0]);
      expect(ids(p.turnModifiers), ['block_guesser@2>$leader']);
      expect(ids(p.malusToReveal), ['block_guesser@2>$leader']);
      expect(p.blockingTeam!.id, trailing);
      expect(p.game.fiesta!.active.where((m) => m.round < 2), isEmpty);
    }

    expectChained(provider);
    expect(provider.needsBlockedGuesser, isTrue);
    await pumpEventQueue();
    final reloaded = GameProvider(); // app tuée avant la continuation M3
    await pumpEventQueue();
    expectChained(reloaded);
    reloaded.setBlockedGuesser(reloaded.blockableGuessers.first.id);
    reloaded.startTurn();
    reloaded.startTurnTimer();
    reloaded.markWordAsGuessed();
    reloaded.endTurn();
    final word = List<String>.from(reloaded.game.wordsGuessedThisTurn);
    reloaded.savePreValidationState(word);
    reloaded.validateWords(word);
    reloaded.restorePreValidationState(); // retour arrière
    expect(reloaded.blockedGuesser, isNotNull);
    expect(ids(reloaded.turnModifiers), ['block_guesser@2>$leader']);
    reloaded.savePreValidationState(word);
    reloaded.validateWords(word);

    // Fin de la continuation M3 : tout le contexte de M2 est parti.
    expect(reloaded.getCurrentTeam()!.id, trailing);
    expect(reloaded.game.fiesta!.active.every((m) => m.round == 3), isTrue);
    expect(reloaded.game.fiesta!.turn.isEmpty, isTrue);
  });

  test(
      'double tap sur « Valider » : les mots sont crédités une fois, le '
      'retour arrière est gardé, la carte de tour de l\'équipe suivante '
      'n\'est pas brûlée (bug antérieur à Fiesta)', () async {
    final provider =
        await givenProvider(['A', 'B', 'C', 'D', 'E'], wordsEach: 4, teams: 2);
    await provider.startGame(fiesta: pickThree);
    // L'équipe menée (2 joueurs) finit M1 : elle joue la continuation, puis
    // vient le premier tour M2 du leader, bloqué.
    final leader = provider.teams.firstWhere((t) => t.playerIds.length == 3).id;
    final trailing = provider.teams.firstWhere((t) => t.id != leader).id;
    if (provider.getCurrentTeam()!.id == trailing) playTurn(provider, 1);
    playTurn(provider, 18);
    expect(playTurn(provider, 20), trailing);
    provider.chooseOffer(trailing, 0);
    provider.nextRound();
    expect(provider.getCurrentTeam()!.id, trailing);

    provider.startTurn();
    provider.startTurnTimer();
    provider.markWordAsGuessed();
    provider.endTurn();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    final scoreBefore = {for (final t in provider.teams) t.id: t.score};
    for (var tap = 0; tap < 2; tap++) {
      provider.savePreValidationState(guessed);
      provider.validateWords(guessed);
    }

    expect(provider.teams.firstWhere((t) => t.id == trailing).score,
        scoreBefore[trailing]! + 1);
    expect(provider.teams.firstWhere((t) => t.id == leader).score,
        scoreBefore[leader]);
    expect(provider.getCurrentTeam()!.id, leader);
    expect(ids(provider.game.fiesta!.active), ['block_guesser@2>$leader']);

    provider.restorePreValidationState();
    expect(provider.game.currentScreen, AppConstants.screenVerification);
    expect(provider.getCurrentTeam()!.id, trailing);
    expect(provider.game.wordsGuessedThisTurn, guessed);
  });

  test(
      'Auto : le coup de pouce montré sur la transition (force « moyenne » '
      'pour un écart de 6) est actif en M2, sans file de choix (AC7)',
      () async {
    final provider = await givenProvider(['Ana', 'Bob'], wordsEach: 11);
    await provider.startGame(
        fiesta: FiestaRules(mode: FiestaMode.auto, symmetric: false));
    final leader = playTurn(provider, 14);
    final trailing = playTurn(provider, 8);

    final gifts = provider.appBoostPreview;
    expect(gifts.map((m) => (m.nature, m.teamId)).toList(), [
      (ModifierNature.bonus, trailing),
      (ModifierNature.malus, leader),
    ]);
    expect(
        gifts.every((m) => kOfferStrength[m.catalogId] == OfferStrength.medium),
        isTrue);
    expect(provider.nextChooserId, isNull);

    provider.nextRound();
    expect(provider.game.currentRound, 2);
    expect(ids(provider.game.fiesta!.active), ids(gifts));
  });

  test('Classique : ni file, ni coup de pouce, nextRound inchangé', () async {
    final provider = await givenProvider(['Ana', 'Bob'], wordsEach: 11);
    await provider.startGame();
    playTurn(provider, 14);
    playTurn(provider, 8);
    expect(provider.nextChooserId, isNull);
    expect(provider.hasPickThree, isFalse);
    expect(provider.appBoostPreview, isEmpty);
    provider.nextRound();
    expect(provider.game.currentRound, 2);
    expect(provider.game.fiesta, isNull);
  });
}
