import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_ensemble.dart';
import 'package:guess_it_all_mobile/models/fiesta/fiesta_rules.dart';
import 'package:guess_it_all_mobile/models/game_settings.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/screens/fiesta_tutorial_screen.dart';
import 'package:guess_it_all_mobile/screens/settings_screen.dart';
import 'package:guess_it_all_mobile/services/fiesta_ensemble_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:provider/provider.dart';

import '../helpers/test_prefs.dart';

Future<GameProvider> givenProvider() async {
  await givenPrefs();
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

/// « App tuée » : un nouveau provider relit ce qui a été écrit.
Future<GameProvider> reopen() async {
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

void main() {
  group('Réglages — survie au démarrage d\'une partie', () {
    test('les réglages avancés modifiés sont écrits sur disque', () async {
      final provider = await givenProvider();

      provider.updateSettings(turnDuration: 45, passPenalty: 2, totalWords: 80);
      await pumpEventQueue();

      final disk = await persistedData(AppConstants.settingsKey);
      expect(disk, isNotNull);
      expect(disk!['turnDuration'], 45);
      expect(disk['passPenalty'], 2);
      expect(disk['totalWords'], 80);
    });

    test('démarrer une nouvelle partie NE réinitialise PAS les réglages',
        () async {
      // Le bug : les trois boutons de l'accueil appelaient clearLocalStorage(),
      // qui fait `_settings = GameSettings.initial()` PUIS `_saveSettings()` —
      // donc écrase sur disque la durée de tour, la pénalité, les catégories et
      // les difficultés. Un joueur qui réglait ses paramètres les reperdait à la
      // partie suivante, et même en rouvrant l'app.
      final provider = await givenProvider();

      provider.updateSettings(
        turnDuration: 45,
        passPenalty: 2,
        selectedCategories: const ['musique', 'marques'],
        selectedDifficultyLevels: const [3, 4],
      );
      await pumpEventQueue();

      await provider.startNewGame();
      await pumpEventQueue();

      expect(provider.settings.turnDuration, 45);
      expect(provider.settings.passPenalty, 2);
      expect(provider.settings.selectedCategories, ['musique', 'marques']);
      expect(provider.settings.selectedDifficultyLevels, [3, 4]);

      final disk = await persistedData(AppConstants.settingsKey);
      expect(disk!['turnDuration'], 45,
          reason:
              'c\'est le disque que relira la prochaine ouverture de l\'app');
      expect(disk['passPenalty'], 2);
      expect(disk['selectedCategories'], ['musique', 'marques']);
      expect(disk['selectedDifficultyLevels'], [3, 4]);
    });

    test('une nouvelle partie efface bien la session et l\'état de jeu',
        () async {
      // Le pendant du test précédent : « garde les réglages » ne doit pas devenir
      // « ne nettoie plus rien ». Sans ça, une implémentation qui ne fait RIEN
      // passerait le test ci-dessus.
      final provider = await givenProvider();

      provider.addPlayer('Alice');
      provider.addPlayer('Bob');
      await pumpEventQueue();
      expect(provider.players, hasLength(2));

      await provider.startNewGame();
      await pumpEventQueue();

      expect(provider.players, isEmpty, reason: 'la session doit être effacée');
      expect(provider.teams, isEmpty);
      expect(await rawString(AppConstants.gameStateKey), isNull);
      expect(await rawString(AppConstants.gameSessionKey), isNull);
    });

    test('le bouton « Réinitialiser » des réglages, LUI, remet les défauts',
        () async {
      // clearLocalStorage garde une raison d'exister : la remise à zéro
      // explicite, avec confirmation, depuis l'écran de réglages.
      final provider = await givenProvider();

      provider.updateSettings(turnDuration: 45, passPenalty: 2);
      provider.setPendingFiesta(classicEnsemble.rules);
      await pumpEventQueue();

      await provider.clearLocalStorage();
      await pumpEventQueue();

      expect(provider.settings.turnDuration, AppConstants.defaultTurnDuration);
      expect(provider.settings.passPenalty, AppConstants.defaultPassPenalty);
      // Tout réinitialiser = retour au Classique par défaut.
      expect(provider.pendingFiesta, isNull);

      final disk = await persistedData(AppConstants.settingsKey);
      expect(disk!['turnDuration'], AppConstants.defaultTurnDuration);
    });

    test('les réglages sont relus au démarrage suivant de l\'app', () async {
      // Simule la fermeture / réouverture : un nouveau GameProvider sur le même
      // stockage doit retrouver les réglages.
      final provider = await givenProvider();
      provider.updateSettings(turnDuration: 50, totalWords: 60);
      await pumpEventQueue();

      final reouverture = GameProvider();
      await pumpEventQueue();

      expect(reouverture.settings.turnDuration, 50);
      expect(reouverture.settings.totalWords, 60);
    });
  });

  group('Dernier choix en cache (app tuée, nouvelle partie)', () {
    test('chaque valeur de l\'écran Paramètres est relue', () async {
      final provider = await givenProvider();
      provider.updateSettings(
        numberOfTeams: 3,
        numberOfPlayers: 7,
        wordChoice: AppConstants.wordChoiceCustom,
        totalWords: 60,
        turnDuration: 50,
        passPenalty: 2,
        selectedCategories: const ['musique'],
        selectedDifficultyLevels: const [2, 4],
      );
      await pumpEventQueue();

      final s = (await reopen()).settings;
      expect(s.numberOfTeams, 3);
      expect(s.numberOfPlayers, 7);
      expect(s.wordChoice, AppConstants.wordChoiceCustom);
      expect(s.totalWords, 60);
      expect(s.turnDuration, 50);
      expect(s.passPenalty, 2);
      expect(s.selectedCategories, ['musique']);
      expect(s.selectedDifficultyLevels, [2, 4]);
    });

    test('réglages d\'avant cette clé : Classique', () {
      expect(GameSettings.fromJson(const {}).fiestaEnabled, isFalse);
      expect(
          GameSettings.fromJson(const {'fiestaEnabled': 'oui'}).fiestaEnabled,
          isFalse);
    });

    test('Classique reste Classique, Fiesta reste Fiesta', () async {
      final provider = await givenProvider();
      expect((await reopen()).pendingFiesta, isNull);

      provider.setPendingFiesta(classicEnsemble.rules);
      await pumpEventQueue();
      final reopened = await reopen();
      expect(reopened.pendingFiesta?.ensembleName, 'Fiesta classique');
      await reopened.startNewGame();
      expect(reopened.pendingFiesta?.ensembleName, 'Fiesta classique');

      provider.setPendingFiesta(null);
      await pumpEventQueue();
      expect((await reopen()).pendingFiesta, isNull);
    });

    test(
        'Personnalisé : le dernier ensemble utilisé ; supprimé ou illisible → '
        'Fiesta classique', () async {
      final provider = await givenProvider();
      final service = FiestaEnsembleService();
      final mine = (await service.create(FiestaRules(ensembleName: 'Soirée')))!;
      await service.markUsed(mine.id);
      provider.setPendingFiesta(mine.rules);
      await pumpEventQueue();

      FiestaRules? pending = (await reopen()).pendingFiesta;
      expect(pending?.ensembleName, 'Soirée');
      expect(pending?.toJson(), mine.rules.toJson());

      final reopened = await reopen();
      await reopened.startNewGame();
      expect(reopened.pendingFiesta?.ensembleName, 'Soirée');

      await service.markUsed('provided_pro');
      pending = (await reopen()).pendingFiesta;
      expect(pending?.ensembleName, 'Pro Player');

      await service.markUsed(mine.id);
      await service.delete(mine.id);
      pending = (await reopen()).pendingFiesta;
      expect(pending?.ensembleName, classicEnsemble.name);

      await service.markUsed('illisible');
      pending = (await reopen()).pendingFiesta;
      expect(pending?.ensembleName, classicEnsemble.name);
    });

    test(
        'partie suspendue : elle garde sa config, le dernier choix reste celui '
        'du joueur', () async {
      await givenPrefs();
      givenFakePlatformPlugins();
      final provider = GameProvider();
      await pumpEventQueue();
      for (final name in ['Ana', 'Bob']) {
        final id = (provider.addPlayer(name)['player'] as dynamic).id as String;
        provider.updatePlayerWords(id, ['mot-$name']);
      }
      provider.createTeams();
      provider.randomizeTeams();
      provider.setPendingFiesta(classicEnsemble.rules);
      await provider.startGame();
      await pumpEventQueue();

      final classicGame = await reopen();
      expect(classicGame.isFiesta, isFalse);
      expect(classicGame.pendingFiesta, isNull,
          reason: 'en partie, `pendingFiesta` = `fiesta?.rules`');
      expect(classicGame.settings.fiestaEnabled, isTrue);
      await classicGame.startNewGame();
      expect(classicGame.pendingFiesta?.ensembleName, 'Fiesta classique');
    });

    testWidgets(
        'le tuto Fiesta s\'ouvre à un choix actif, pas à une restauration',
        (tester) async {
      await givenPrefs();
      final first = GameProvider();
      await tester.runAsync(() => pumpEventQueue());
      first.setPendingFiesta(classicEnsemble.rules);
      await tester.runAsync(() => pumpEventQueue());

      final provider = GameProvider();
      await tester.runAsync(() => pumpEventQueue());
      expect(provider.pendingFiesta?.ensembleName, 'Fiesta classique');
      await tester.pumpWidget(
        ChangeNotifierProvider<GameProvider>.value(
          value: provider,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(FiestaTutorialScreen), findsNothing);

      await tester.tap(find.text('Classique'));
      await tester.pump();
      await tester.tap(find.text('Fiesta'));
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(FiestaTutorialScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
