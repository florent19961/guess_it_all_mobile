import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/persisted_schema.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';

import '../helpers/test_prefs.dart';

void main() {
  final storage = StorageService();

  group('StorageService — rétro-compatibilité avec la version en store', () {
    test('relit un blob écrit AVANT le versionnage (format non enveloppé)',
        () async {
      // 🔴 Le cas qui compte le plus : ce format est celui qui vit aujourd'hui
      // sur les téléphones. Le rejeter ferait perdre ses réglages à tout le parc
      // au moment où `upgrader` pousse la mise à jour.
      await givenPrefs({
        AppConstants.settingsKey:
            jsonEncode({'turnDuration': 45, 'passPenalty': 2}),
      });

      final loaded = await storage.loadSettings();

      expect(loaded, isNotNull);
      expect(loaded!['turnDuration'], 45);
      expect(loaded['passPenalty'], 2);
    });

    test('ré-écrit ensuite au format versionné', () async {
      await givenPrefs({
        AppConstants.settingsKey: jsonEncode({'turnDuration': 45}),
      });

      await storage.saveSettings({'turnDuration': 50});

      final raw = jsonDecode((await rawString(AppConstants.settingsKey))!)
          as Map<String, dynamic>;
      expect(raw['schemaVersion'], kCurrentSchemaVersion);
      expect(raw['data'], {'turnDuration': 50});
    });

    test('un aller-retour versionné rend la donnée intacte', () async {
      await givenPrefs();

      await storage.saveGameState({'game': 'x', 'players': []});
      final loaded = await storage.loadGameState();

      expect(loaded, {'game': 'x', 'players': []});
    });
  });

  group('StorageService — quarantaine', () {
    test('un JSON cassé est SUPPRIMÉ, pour que l\'échec ne se rejoue pas',
        () async {
      // Sans suppression, l'app rééchouait à chaque démarrage : l'utilisateur
      // était bloqué définitivement, sans aucun moyen de s'en sortir.
      await givenPrefs(
          {AppConstants.gameStateKey: '{ ceci n\'est pas du JSON'});

      expect(await storage.loadGameState(), isNull);
      expect(await rawString(AppConstants.gameStateKey), isNull,
          reason: 'le blob fautif doit avoir été retiré du stockage');
    });

    test('un blob écrit par une version PLUS RÉCENTE est mis en quarantaine',
        () async {
      await givenPrefs({
        AppConstants.settingsKey: jsonEncode({
          'schemaVersion': kCurrentSchemaVersion + 1,
          'data': {'champInconnu': true},
        }),
      });

      expect(await storage.loadSettings(), isNull);
      expect(await rawString(AppConstants.settingsKey), isNull);
    });

    test('une clé ABSENTE n\'est pas une quarantaine et ne casse rien',
        () async {
      // Pendant des tests ci-dessus : « supprime ce qui est illisible » ne doit
      // pas devenir « supprime tout ». Le cas d'une première ouverture est
      // normal.
      await givenPrefs();

      expect(await storage.loadSettings(), isNull);
      expect(await storage.loadGameState(), isNull);
    });

    test('une donnée VALIDE n\'est jamais supprimée', () async {
      await givenPrefs();
      await storage.saveSettings({'turnDuration': 45});

      expect(await storage.loadSettings(), {'turnDuration': 45});
      expect(await rawString(AppConstants.settingsKey), isNotNull,
          reason: 'lire une donnée saine ne doit pas la détruire');

      // Deux lectures successives donnent le même résultat.
      expect(await storage.loadSettings(), {'turnDuration': 45});
    });
  });
}
