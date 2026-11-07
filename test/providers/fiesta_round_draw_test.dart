import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/symmetric_draw.dart';
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
      'Fiesta Auto : le tirage de M2 ne bouge ni après un retour arrière ni '
      'après une app tuée sur la transition, et remplace celui de M1 dès le '
      '« Manche suivante », continuation comprise', () async {
    final provider = await givenReadyProvider();
    await provider.startGame(
        fiesta: FiestaRules(drawCount: 1, modifiers: {
      for (final def in kModifierCatalog)
        if (canBeRoundRule(def)) def.id: const ModifierSetting(draw: true),
    }));
    expect(provider.game.fiesta!.active, isNotEmpty);
    expect(provider.game.fiesta!.active.every((m) => m.round == 1), isTrue);

    playWholeRound(provider);
    expect(provider.game.currentScreen, AppConstants.screenTransition);
    final expected = ids(roundModifiers(provider.game.fiesta!.rules,
        gameId: provider.game.gameId!, round: 2));
    expect(expected, isNotEmpty);

    // Retour arrière depuis la transition, puis revalidation : rien n'a bougé.
    final m1 = ids(provider.game.fiesta!.active);
    provider.restorePreValidationState();
    final guessed = List<String>.from(provider.game.wordsGuessedThisTurn);
    provider.savePreValidationState(guessed);
    provider.validateWords(guessed);
    expect(ids(provider.game.fiesta!.active), m1);

    // App tuée sur la transition : rien à relire d'autre que l'état de M1.
    await pumpEventQueue();
    final reloaded = GameProvider();
    await pumpEventQueue();
    expect(reloaded.game.currentScreen, AppConstants.screenTransition);
    expect(ids(reloaded.game.fiesta!.active), m1);

    reloaded.nextRound();
    // Les règles de M2 valent tout de suite, y compris pour la continuation.
    expect(ids(reloaded.game.fiesta!.active), expected);
    expect(reloaded.isContinuation, isTrue);
    expect(ids(reloaded.currentTeamModifiers), expected);
    playEmptyTurn(reloaded);
    expect(ids(reloaded.game.fiesta!.active), expected);
    expect(ids(reloaded.currentTeamModifiers), expected);
  });

  test('Classique : ni fiesta, ni tirage, ni badge, à aucune étape', () async {
    final provider = await givenReadyProvider();
    await provider.startGame();
    playWholeRound(provider);
    provider.nextRound();
    expect(provider.game.fiesta, isNull);
    expect(provider.currentTeamModifiers, isEmpty);
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
        drawCount: 0,
        modifiers: {
          'no_pass': const ModifierSetting(always: true),
        },
      ),
    );
    provider.startTurn();
    provider.startTurnTimer();

    final game = AnalyticsService().currentGame!;
    expect(game.gameMode, 'fiesta_custom');
    final shown =
        game.events.lastWhere((e) => e.eventType == WordEventType.shown);
    expect(shown.modifiers, ['no_pass']);
  });
}
