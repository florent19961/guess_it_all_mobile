import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/storage_service.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';
import 'package:guess_it_all_mobile/widgets/help/first_game_help.dart';

import '../helpers/test_prefs.dart';

/// Chemin de mise à jour depuis la version en store : seul
/// `guessItAll_word_history` existe, et il suffit à marquer un joueur déjà
/// venu.
///
/// `WordHistoryService` est un singleton sans reset : le cas « install neuve »
/// passe en premier, sans `initialize()` (cache nul = historique vide), pour
/// que le cas « store » puisse ensuite initialiser le service pour de bon.
void main() {
  final storage = StorageService();

  test('install neuve (prefs vides) : tuto et première partie à false',
      () async {
    await givenPrefs();
    await FirstGameHelp.initAtStartup();
    expect(await storage.hasSeenTutorial(), isFalse);
    expect(await storage.isFirstGameDone(), isFalse);
  });

  test('build du store (word_history seul) : tuto et première partie à true',
      () async {
    await givenPrefs({'guessItAll_word_history': '{"chat":2}'});
    await WordHistoryService().initialize();
    await FirstGameHelp.initAtStartup();
    expect(await storage.hasSeenTutorial(), isTrue);
    expect(await storage.isFirstGameDone(), isTrue);
  });
}
