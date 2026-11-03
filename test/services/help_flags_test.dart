import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
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

    // Joueur de la version en store (historique des mots, flags absents) :
    // rattrapé au démarrage ; un false écrit (« Revoir les aides ») prime.
    await givenPrefs({WordHistoryService.storageKey: '{"chat":1}'});
    await storage.inferHelpFlagsFromPastGames();
    expect(await storage.hasSeenTutorial(), isTrue);
    expect(await storage.isFirstGameDone(), isTrue);
    await givenPrefs({
      WordHistoryService.storageKey: '{"chat":1}',
      AppConstants.firstGameDoneKey: false,
    });
    await storage.inferHelpFlagsFromPastGames();
    expect(await storage.isFirstGameDone(), isFalse);
  });
}
