import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_recap.dart';
import 'package:guess_it_all_mobile/models/fiesta/turn_effects.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

/// 🔴 Règle 7 : « Deux mots à la fois » est retiré du jeu, mais des blobs écrits
/// par la version en store le contiennent encore.

Future<GameProvider> givenStartedGame() async {
  await givenPrefs();
  givenFakePlatformPlugins();
  final provider = GameProvider();
  await pumpEventQueue();
  for (final name in ['A', 'B', 'C', 'D']) {
    final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
    provider.updatePlayerWords(id, ['$name-1', '$name-2', '$name-3']);
  }
  provider.createTeams();
  provider.randomizeTeams();
  provider.updateSettings(passPenalty: 0);
  await provider.startGame(fiesta: FiestaRules(allCount: 1));
  return provider;
}

/// La partie de [provider] réécrite sur disque par l'ancienne version
/// ([patch] reçoit le bloc `fiesta` et le bloc `game`), puis relue au
/// redémarrage de l'app.
Future<GameProvider> reloadedAsOldBlob(
  GameProvider provider,
  void Function(Map<String, dynamic> fiesta, Map<String, dynamic> game) patch,
) async {
  await pumpEventQueue();
  final saved = (await StorageService().loadGameState())!;
  final game = saved['game'] as Map<String, dynamic>;
  final fiesta = game['fiesta'] as Map<String, dynamic>;
  final teamId = provider.getCurrentTeam()!.id;
  (fiesta['rules']['modifiers'] as Map)['two_words'] = {
    'always': false,
    'draw': false,
    'charges': 1,
  };
  fiesta['earned'] = [
    ...(fiesta['earned'] as List? ?? const []),
    {'catalogId': 'two_words', 'teamId': teamId, 'round': 1},
  ];
  patch(fiesta, game);
  await StorageService().saveGameState(saved);
  final reloaded = GameProvider();
  await pumpEventQueue();
  return reloaded;
}

void main() {
  test(
      'tour en cours avec la carte B à l\'écran : jouable, un seul mot, B reste '
      'à faire deviner et finit par sortir', () async {
    final before = await givenStartedGame();
    before.startTurn();
    before.startTurnTimer();
    final a = before.game.currentWord!;
    final b = before.game.remainingWords.firstWhere((w) => w != a);
    final teamId = before.getCurrentTeam()!.id;

    final p = await reloadedAsOldBlob(before, (fiesta, game) {
      fiesta['turn'] = {'twoWords': 'spent', 'secondWord': b};
      fiesta['chargesUsed'] = [
        {'catalogId': 'two_words', 'teamId': teamId, 'round': 1, 'turn': 1},
      ];
    });

    expect(p.isFiesta, isTrue, reason: 'jamais retombé en Classique');
    expect(p.game.currentScreen, AppConstants.screenTurn);
    expect(p.game.currentWord, a);
    expect(p.game.remainingWords, contains(b));
    expect(p.spentBonuses, isEmpty, reason: 'la cartouche ne joue plus');
    expect(p.effectiveRemainingWordsCount, p.game.remainingWords.length - 1,
        reason: 'un seul mot à l\'écran');

    // L'historique de la partie, lui, ne perd rien.
    final fiesta = p.game.fiesta!;
    expect(fiesta.chargesUsed.single.catalogId, 'two_words');
    expect(fiesta.earned.map((e) => e.catalogId), contains('two_words'));
    expect(fiesta.rules.modifiers.keys, contains('two_words'));

    // On joue jusqu'à la fin de la manche : chaque mot passe une fois à l'écran.
    final total = p.game.remainingWords.length;
    final shown = <String>[];
    while (p.game.currentWord != null) {
      shown.add(p.game.currentWord!);
      p.markWordAsGuessed();
    }
    expect(shown.toSet(), hasLength(total));
    expect(shown, contains(b));
    expect(p.game.currentScreen, AppConstants.screenVerification);
    expect(p.game.remainingWords, isEmpty);

    // Une fois réécrite, la partie n'a plus trace du tour à deux cartes.
    await pumpEventQueue();
    final turn = ((await StorageService().loadGameState())!['game']['fiesta']
        as Map)['turn'];
    expect(turn, isNull);
  });

  test(
      'vérification avec une carte B expirée : elle n\'est ni comptée ni '
      'perdue, elle reste dans le pool', () async {
    final before = await givenStartedGame();
    before.startTurn();
    before.startTurnTimer();
    final a = before.game.currentWord!;
    final b = before.game.remainingWords.firstWhere((w) => w != a);
    before.endTurn();

    final p = await reloadedAsOldBlob(before, (fiesta, game) {
      fiesta['turn'] = {'twoWords': 'spent', 'secondExpiredWord': b};
    });
    expect(p.game.currentScreen, AppConstants.screenVerification);

    final team = p.getCurrentTeam()!.id;
    p.validateWords([a]);

    expect(p.game.remainingWords, contains(b));
    expect(p.game.remainingWords, isNot(contains(a)));
    expect(p.teams.firstWhere((t) => t.id == team).score, 1);
  });

  test(
      'Deux mots allumé à l\'avant-tour : éteint à la relecture, ni dépensé ni '
      'proposé, même gagné en cartouche', () async {
    final before = await givenStartedGame();
    final p = await reloadedAsOldBlob(before, (fiesta, game) {
      fiesta['turn'] = {'twoWords': 'armed'};
    });

    expect(p.game.currentScreen, isNot(AppConstants.screenTurn));
    expect(p.bonusesThisTurn, isEmpty);
    expect(p.reserve.map((c) => c.catalogId), isNot(contains('two_words')));

    p.startTurn();
    p.startTurnTimer();
    expect(p.game.fiesta!.chargesUsed, isEmpty);
    expect(p.spentBonuses, isEmpty);
  });

  test('reprise des choix d\'un joueur bloqué : Deux mots n\'est pas rallumé',
      () async {
    final before = await givenStartedGame();
    final fromPlayer = before.getCurrentPlayer()!.id;
    var p = await reloadedAsOldBlob(before, (fiesta, game) {
      fiesta['turn'] = {
        'replaced': {
          'playerId': fromPlayer,
          'bonuses': ['two_words'],
        },
      };
    });
    expect(p.replacedPlayer, isNull,
        reason: 'plus rien à reprendre : pas de lien vide');

    p = await reloadedAsOldBlob(p, (fiesta, game) {
      fiesta['earned'] = [
        ...fiesta['earned'] as List,
        {
          'catalogId': 'double_points',
          'teamId': p.getCurrentTeam()!.id,
          'round': 1
        },
      ];
      fiesta['turn'] = {
        'replaced': {
          'playerId': fromPlayer,
          'bonuses': ['two_words', 'double_points'],
        },
      };
    });
    p.reuseReplacedChoices();
    expect(p.bonusesThisTurn, ['double_points']);
  });

  group('Lecture seule', () {
    test('modifierById répond, le catalogue ne le contient plus', () {
      expect(modifierById('two_words')!.name, 'Deux mots à la fois');
      expect(kModifierCatalog.map((d) => d.id), isNot(contains('two_words')));
      expect(kChargeBonusKeys, isNot(contains('two_words')));
      expect(kCartridgeOnlyIds, isNot(contains('two_words')));
      expect(areCompatible('no_pass', 'two_words'), isTrue);
    });

    test('instance, cartouche gagnée et dépensée restent lisibles et nommées',
        () {
      final instance = ModifierInstance.tryFromJson({
        'catalogId': 'two_words',
        'scope': 'round',
        'target': 'both',
        'charges': 1,
        'nature': 'bonus',
        'round': 1,
      });
      expect(instance, isNotNull);

      final earned = EarnedCartridge.tryFromJson(
          {'catalogId': 'two_words', 'teamId': 'a', 'round': 2})!;
      final used = ChargeUse.tryFromJson(
          {'catalogId': 'two_words', 'teamId': 'a', 'round': 2})!;
      final lines = formatModifierRecap(
        buildModifierRecap(
          rules: FiestaRules(),
          chargesUsed: [used],
          earned: [earned],
          gameId: 'g',
          roundsPlayed: 2,
        ),
        teamNames: const {'a': 'Les A'},
      );
      expect(
          lines.map((l) => l.detail).join(), contains('Deux mots à la fois'));
      expect(lines.map((l) => l.detail).join(), isNot(contains('two_words')));
    });

    test(
        'ensemble enregistré avec Deux mots : relu sans le perdre, sans effet '
        'sur le jeu ni sur le doublon', () {
      final saved = FiestaEnsemble.tryFromJson({
        'id': 'e1',
        'rules': {
          'format': FiestaRules.format,
          'ensembleName': 'Avec deux mots',
          'modifiers': {
            'two_words': {'always': false, 'draw': false, 'charges': 2},
            'reversed': {'always': true, 'draw': false, 'charges': 0},
          },
        },
      })!;
      expect(saved.rules.modifiers.keys, contains('two_words'));
      expect(
        settingsKey(saved.rules),
        settingsKey(FiestaRules(modifiers: const {
          'reversed': ModifierSetting(always: true),
        })),
      );
    });
  });
}
