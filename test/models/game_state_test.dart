import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_state.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_catalog.dart';
import 'package:guess_it_all_mobile/models/fiesta/modifier_instance.dart';
import 'package:guess_it_all_mobile/models/game_state.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

HistoryEntry _entry({int round = 1, int turn = 1}) => HistoryEntry(
      round: round,
      turn: turn,
      teamId: 'team-0',
      playerId: 'player-0',
      wordsGuessed: const ['chat'],
      wordsInvalidated: const [],
      wordsPassed: const ['chien'],
      timeSpent: 30,
    );

void main() {
  group('GameState — sérialisation', () {
    test('un aller-retour JSON préserve TOUS les champs', () {
      final original = GameState(
        gameId: 'abc-123',
        currentScreen: AppConstants.screenTurn,
        currentRound: 2,
        currentTurn: 5,
        currentTeamIndex: 1,
        currentPlayerIndexInTeam: 2,
        teamPlayOrder: const [1, 0],
        playerOrderByTeam: const {
          'team-0': [0, 1],
          'team-1': [1, 0],
        },
        currentTurnIndex: 3,
        allWords: const ['chat', 'chien'],
        remainingWords: const ['chien'],
        currentWord: 'chien',
        wordsGuessedThisTurn: const ['chat'],
        passedWordsThisTurn: const ['chien'],
        expiredWord: 'souris',
        timeRemaining: 12,
        turnBonusTime: 7,
        turnStartTimestamp: 1000,
        turnEndTimestamp: 31000,
        pausedTimeRemaining: 12,
        isGameSuspended: true,
        suspendedScreen: AppConstants.screenTurn,
        history: [_entry()],
        pendingBonusTurnId: 4,
        preValidationSnapshot: const {'foo': 'bar'},
        restoredValidatedWords: const ['chat'],
      );

      final restored = GameState.fromJson(original.toJson());

      // Dérivé du JSON, pas énuméré : un champ ajouté au modèle mais oublié dans
      // toJson/fromJson fait tomber ce test.
      expect(restored.toJson(), equals(original.toJson()));
    });

    test('un JSON vide rend un état initial jouable, sans lever', () {
      final state = GameState.fromJson(const {});

      expect(state.currentScreen, AppConstants.screenHome);
      expect(state.currentRound, 1);
      expect(state.currentTurn, 1);
      expect(state.allWords, isEmpty);
      expect(state.history, isEmpty);
      expect(state.timeRemaining, AppConstants.defaultTurnDuration);
    });
  });

  group('GameState — copyWith', () {
    test(
        'les drapeaux clearX remettent le champ à null, contrairement au passage de null',
        () {
      final base = GameState(
        currentWord: 'chat',
        turnEndTimestamp: 31000,
        expiredWord: 'souris',
      );

      // Passer null ne fait rien (c'est la sémantique `?? this.x`) …
      expect(base.copyWith(currentWord: null).currentWord, 'chat');
      // … seul le drapeau efface réellement.
      expect(base.copyWith(clearCurrentWord: true).currentWord, isNull);
      expect(
          base.copyWith(clearTurnEndTimestamp: true).turnEndTimestamp, isNull);
      expect(base.copyWith(clearExpiredWord: true).expiredWord, isNull);
    });

    test('copie les collections au lieu de les partager', () {
      final base = GameState(
        allWords: ['chat'],
        history: [_entry()],
        playerOrderByTeam: {
          'team-0': [0, 1],
        },
      );
      final copy = base.copyWith();

      copy.allWords.add('chien');
      copy.history.add(_entry(turn: 2));
      copy.playerOrderByTeam['team-0']!.add(2);

      expect(base.allWords, ['chat']);
      expect(base.history, hasLength(1));
      expect(base.playerOrderByTeam['team-0'], [0, 1],
          reason:
              'la copie de playerOrderByTeam doit être profonde, pas seulement Map.from');
    });
  });

  group('GameState — Fiesta (champ optionnel, absent = Classique)', () {
    const instance = ModifierInstance(
      catalogId: 'no_pass',
      scope: ModifierScope.round,
      target: ModifierTarget.both,
      charges: 0,
      nature: ModifierNature.malus,
      round: 2,
    );

    FiestaState fiestaState() => FiestaState(
          rules: FiestaRules(
            mode: FiestaMode.custom,
            ensembleName: 'Soirée chez Max',
            modifiers: const {
              'free_pass': ModifierSetting(
                active: true,
                arrival: ModifierArrival.offer,
                startRound: 2,
                charges: 3,
              ),
              'draw': ModifierSetting(
                active: true,
                arrival: ModifierArrival.fixed,
                startRound: 3,
                fixedRound: 3,
                charges: 0,
              ),
            },
            oneOfThree: true,
            catchUp:
                const CatchUpRules(b1: 2, b2: 4, cap: 20, mal: 1, malCap: 10),
            drawCount: 2,
            oneAnswer: false,
          ),
          active: const [instance],
        );

    test('un blob Classique (sans `fiesta`) reste Classique, sans bruit', () {
      // Le blob de la version en store : toJson() d'avant la story, sans
      // la clé. C'est ce qui est sur les téléphones des joueurs.
      final legacy = GameState(gameId: 'abc', currentRound: 2).toJson()
        ..remove('fiesta');

      final restored = GameState.fromJson(legacy);

      expect(restored.fiesta, isNull);
      expect(restored.toJson(), equals(legacy),
          reason: 'une partie Classique ne doit pas écrire `fiesta: null`');
      expect(restored.toJson().containsKey('fiesta'), isFalse);
    });

    test('un aller-retour JSON préserve rules et active à l\'identique', () {
      final original = GameState(gameId: 'abc', fiesta: fiestaState());

      final restored = GameState.fromJson(original.toJson());

      expect(restored.fiesta, isNotNull);
      expect(restored.toJson(), equals(original.toJson()));
      expect(restored.fiesta!.rules.modifiers.keys, ['free_pass', 'draw']);
      expect(restored.fiesta!.active.single.catalogId, 'no_pass');
    });

    test('une instance inconnue ou mal formée est ignorée, le reste se relit',
        () {
      final json = GameState(gameId: 'abc', fiesta: fiestaState()).toJson();
      final fiesta = json['fiesta'] as Map<String, dynamic>;
      fiesta['active'] = [
        instance.toJson(),
        {...instance.toJson(), 'catalogId': 'from_the_future'},
        {...instance.toJson(), 'charges': 'deux'},
        'pas un objet',
      ];
      // Un réglage d'id inconnu dans les règles est ignoré seul, lui aussi.
      (fiesta['rules'] as Map<String, dynamic>)['modifiers']['unknown'] = {
        'active': true,
        'arrival': 'draw',
        'startRound': 1,
        'charges': 0,
      };

      final restored = GameState.fromJson(json);

      expect(restored.gameId, 'abc');
      expect(restored.fiesta!.active.map((e) => e.catalogId), ['no_pass']);
      expect(restored.fiesta!.rules.modifiers.keys, ['free_pass', 'draw']);
    });

    test(
        'un `fiesta` qui n\'est pas un objet, ou aux règles illisibles, '
        'donne une partie Classique', () {
      final base = GameState(gameId: 'abc').toJson();

      expect(GameState.fromJson({...base, 'fiesta': 'oui'}).fiesta, isNull);
      expect(GameState.fromJson({...base, 'fiesta': 42}).fiesta, isNull);
      expect(
          GameState.fromJson({...base, 'fiesta': <String, dynamic>{}}).fiesta,
          isNull);
      expect(
          GameState.fromJson({
            ...base,
            'fiesta': {
              'rules': {'mode': 'party'},
              'active': [],
            },
          }).fiesta,
          isNull);
      expect(GameState.fromJson({...base, 'fiesta': 'oui'}).gameId, 'abc');
    });
  });

  group('HistoryEntry', () {
    test('un aller-retour JSON préserve les champs', () {
      final original = _entry(round: 3, turn: 7);
      expect(HistoryEntry.fromJson(original.toJson()).toJson(),
          equals(original.toJson()));
    });
  });
}
