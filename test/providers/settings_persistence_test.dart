import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/providers/game_provider.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

Future<GameProvider> givenProvider() async {
  await givenPrefs();
  final provider = GameProvider();
  await pumpEventQueue();
  return provider;
}

/// Relit les réglages tels qu'ils sont RÉELLEMENT écrits sur disque.
///
/// C'est la seule assertion qui compte ici : l'objet en mémoire peut être juste
/// alors que le disque a déjà été écrasé — et c'est le disque que la prochaine
/// ouverture de l'app relira.
Future<Map<String, dynamic>?> settingsOnDisk() async {
  final raw = await rawString(AppConstants.settingsKey);
  return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  group('Réglages — survie au démarrage d\'une partie', () {
    test('les réglages avancés modifiés sont écrits sur disque', () async {
      final provider = await givenProvider();

      provider.updateSettings(turnDuration: 45, passPenalty: 2, totalWords: 80);
      await pumpEventQueue();

      final disk = await settingsOnDisk();
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

      final disk = await settingsOnDisk();
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
      await pumpEventQueue();

      await provider.clearLocalStorage();
      await pumpEventQueue();

      expect(provider.settings.turnDuration, AppConstants.defaultTurnDuration);
      expect(provider.settings.passPenalty, AppConstants.defaultPassPenalty);

      final disk = await settingsOnDisk();
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
}
