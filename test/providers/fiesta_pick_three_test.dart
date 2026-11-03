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
    {required int wordsEach}) async {
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

/// L'équipe qui joue fait deviner [n] mots, puis le tour est validé (fin de
/// manche si le pool est vide). Rend l'id de l'équipe qui a joué.
String playTurn(GameProvider provider, int n) {
  final teamId = provider.getCurrentTeam()!.id;
  provider.startTurn();
  provider.startTurnTimer();
  for (var i = 0; i < n; i++) {
    provider.markWordAsGuessed();
  }
  if (provider.game.currentScreen == AppConstants.screenGame) {
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
