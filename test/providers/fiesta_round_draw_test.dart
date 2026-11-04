import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/word_event.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/analytics_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// Un provider prêt à lancer une partie : 2 joueurs, 2 équipes,
/// [wordsEach] mots chacun.
Future<GameProvider> givenReadyProvider({int wordsEach = 1}) async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in ['Ana', 'Bob']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(
        id, [for (var i = 0; i < wordsEach; i++) 'mot-$name-$i']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  return provider;
}

/// Un seul tour fait deviner les 2 mots, puis passe par la vérification :
/// fin de la manche, écran de transition.
void playWholeRound(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.markWordAsGuessed();
  provider.markWordAsGuessed();
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
}

/// Un tour qui fait deviner 1 mot sans finir la manche, validé.
void playOneWordTurn(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.markWordAsGuessed();
  provider.endTurn();
  final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
  provider.savePreValidationState(guessed);
  provider.validateWords(guessed);
}

/// Un tour sans rien deviner, validé vide : passe la main.
void playEmptyTurn(GameProvider provider) {
  provider.startTurn();
  provider.startTurnTimer();
  provider.endTurn();
  provider.savePreValidationState(const []);
  provider.validateWords(const []);
}

List<String> ids(Iterable<ModifierInstance> mods) =>
    mods.map((m) => '${m.catalogId}@${m.round}').toList();

void main() {
  test(
      'Fiesta Auto : le tirage de M2 est visible dès la transition, identique '
      'après un retour arrière et après une app tuée, puis actif au '
      '« Manche suivante » à la place de celui de M1', () async {
    final provider = await givenReadyProvider();
    // Sans auto-calibrage : son coup de pouce (2-10) s'ajouterait au tirage
    // selon la graine, ce test ne regarde que le tirage.
    await provider.startGame(
        fiesta: FiestaRules(mode: FiestaMode.auto, autoCalibrate: false));
    expect(provider.game.fiesta!.active, isNotEmpty);
    expect(provider.game.fiesta!.active.every((m) => m.round == 1), isTrue);

    playWholeRound(provider);
    expect(provider.game.currentScreen, AppConstants.screenTransition);
    final preview = ids(provider.nextRoundModifiers);
    expect(preview, isNotEmpty);

    // Retour arrière depuis la transition, puis revalidation : pas de relance.
    provider.restorePreValidationState();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(ids(provider.nextRoundModifiers), preview);

    // App tuée sur la transition : même tirage à la réouverture.
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.game.currentScreen, AppConstants.screenTransition);
    expect(ids(reloaded.nextRoundModifiers), preview);
    expect(
        ids(reloaded.game.fiesta!.active), ids(provider.game.fiesta!.active));

    reloaded.nextRound();
    // La continuation est le même tour que la fin de M1 : elle garde le tirage
    // de M1, qui part à sa fin ; celui de M2 commence au premier vrai tour.
    final m1 = ids(reloaded.game.fiesta!.active.where((m) => m.round == 1));
    expect(
        ids(reloaded.game.fiesta!.active.where((m) => m.round == 2)), preview);
    expect(ids(reloaded.currentTeamModifiers), m1);
    playEmptyTurn(reloaded);
    expect(ids(reloaded.game.fiesta!.active), preview);
    expect(ids(reloaded.currentTeamModifiers), preview);
  });

  test('Classique : ni fiesta, ni tirage, ni badge, à aucune étape', () async {
    final provider = await givenReadyProvider();
    await provider.startGame();
    playWholeRound(provider);
    expect(provider.nextRoundModifiers, isEmpty);
    provider.nextRound();
    expect(provider.game.fiesta, isNull);
    expect(provider.currentTeamModifiers, isEmpty);
    expect(provider.malusToReveal, isEmpty);
  });

  test(
      'révélation des malus : au premier tour de chaque équipe dans la '
      'manche, plus ensuite', () async {
    final provider = await givenReadyProvider(wordsEach: 2);
    await provider.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        drawCount: 0,
        modifiers: {
          'minus_10s': ModifierSetting(
              active: true, rounds: const {1}, mode: ModifierMode.always),
        },
      ),
    );
    final first = provider.getCurrentTeam()!.id;
    expect(ids(provider.malusToReveal), ['minus_10s@1']);

    playOneWordTurn(provider);
    expect(provider.getCurrentTeam()!.id, isNot(first));
    expect(ids(provider.malusToReveal), ['minus_10s@1']);

    playOneWordTurn(provider);
    expect(provider.getCurrentTeam()!.id, first);
    expect(provider.game.currentRound, 1);
    expect(provider.malusToReveal, isEmpty);
    // Toujours actif, juste plus révélé.
    expect(ids(provider.currentTeamModifiers), ['minus_10s@1']);
  });

  test('révélation dès M2 aussi : jouer en M1 ne compte pas pour M2', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
      fiesta: FiestaRules(mode: FiestaMode.custom, modifiers: {
        'minus_10s': ModifierSetting(
            active: true, rounds: const {1, 2, 3}, mode: ModifierMode.draw),
      }),
    );
    final first = provider.getCurrentTeam()!.id;
    playWholeRound(provider);
    provider.nextRound();
    // La continuation garde l'équipe qui a joué toute la M1. Le malus de 10 s
    // ne s'y applique pas (Q5, 2-6) : il se révèle au premier tour complet.
    expect(provider.getCurrentTeam()!.id, first);
    expect(provider.malusToReveal, isEmpty);
    playEmptyTurn(provider); // la continuation
    expect(provider.getCurrentTeam()!.id, isNot(first));
    expect(ids(provider.malusToReveal), ['minus_10s@2']);
    playEmptyTurn(provider);
    expect(provider.getCurrentTeam()!.id, first);
    expect(ids(provider.malusToReveal), ['minus_10s@2']);
  });

  test(
      'double tap sur « Manche suivante » : un seul passage de manche '
      '(bug antérieur à Fiesta, M1 → M3)', () async {
    final provider = await givenReadyProvider();
    await provider.startGame();
    playWholeRound(provider);
    expect(provider.game.currentScreen, AppConstants.screenTransition);

    provider.nextRound();
    provider.nextRound();

    expect(provider.game.currentRound, 2);
    expect(provider.game.currentScreen, AppConstants.screenGame);
  });

  test(
      'analytics (2-7) : la partie porte son mode, le mot affiché porte les '
      'modificateurs relus de l\'état de la partie', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
      fiesta: FiestaRules(
        mode: FiestaMode.custom,
        drawCount: 0,
        modifiers: {
          'minus_10s': ModifierSetting(
              active: true, rounds: const {1}, mode: ModifierMode.always),
        },
      ),
    );
    provider.startTurn();
    provider.startTurnTimer();

    final game = AnalyticsService().currentGame!;
    expect(game.gameMode, 'fiesta_custom');
    final shown =
        game.events.lastWhere((e) => e.eventType == WordEventType.shown);
    expect(shown.modifiers, ['minus_10s']);
  });
}
