import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/game_history_service.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_prefs.dart';
import 'game_history_test.dart' show game;

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

    // Joueur déjà venu (historique non vide, clés absentes) : déjà vu, écrit
    // une fois ; « Revoir les aides » (false explicite) prime ensuite.
    await givenPrefs();
    await GameHistoryService().record(game(id: 'old'));
    expect(await storage.hasSeenTutorial(), isTrue);
    expect(await storage.isFirstGameDone(), isTrue);
    expect(
        (await SharedPreferences.getInstance())
            .getBool(AppConstants.firstGameDoneKey),
        isTrue);
    await storage.resetFirstGameDone();
    expect(await storage.isFirstGameDone(), isFalse);
  });
}
