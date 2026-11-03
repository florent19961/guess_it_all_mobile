import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_prefs.dart';

void main() {
  final storage = StorageService();

  test('flags d\'aide : absents = false, puis relus après écriture', () async {
    await givenPrefs();
    expect(await storage.hasSeenTutorial(), isFalse);
    expect(await storage.hasSeenFiestaTutorial(), isFalse);
    expect(await storage.isFirstGameDone(), isFalse);

    await storage.markTutorialSeen();
    await storage.markFiestaTutorialSeen();
    await storage.markFirstGameDone();
    await (await SharedPreferences.getInstance()).reload();
    expect(await storage.hasSeenTutorial(), isTrue);
    expect(await storage.hasSeenFiestaTutorial(), isTrue);
    expect(await storage.isFirstGameDone(), isTrue);

    await storage.resetFirstGameDone();
    expect(await storage.isFirstGameDone(), isFalse);

    // Décidé une fois au démarrage : install neuve → false, et une première
    // partie abandonnée (historique écrit) ne fait rien basculer au
    // redémarrage suivant.
    await givenPrefs();
    await storage.initHelpFlags(playedBefore: false);
    await storage.initHelpFlags(playedBefore: true);
    expect(await storage.hasSeenTutorial(), isFalse);
    expect(await storage.isFirstGameDone(), isFalse);
    // Joueur déjà venu (flags absents) → true.
    await givenPrefs();
    await storage.initHelpFlags(playedBefore: true);
    expect(await storage.hasSeenTutorial(), isTrue);
    expect(await storage.isFirstGameDone(), isTrue);
  });
}
