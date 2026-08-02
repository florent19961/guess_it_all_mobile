import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';

import '../helpers/test_prefs.dart';

const _key = 'guessItAll_word_history';

void main() {
  test('un historique de forme inattendue est mis en quarantaine, pas figé',
      () async {
    // 🔴 `jsonDecode(x) as Map<String, dynamic>` sur `[]` lève un TypeError et
    // NON une FormatException : le service classait donc ça en « panne
    // transitoire », armait `_degraded` et refusait toute sauvegarde — à chaque
    // démarrage, pour toujours, sans jamais nettoyer la clé fautive.
    await givenPrefs({_key: '[]'});

    final service = WordHistoryService();
    await service.initialize();

    expect(await rawString(_key), isNull,
        reason: 'la clé fautive doit être supprimée pour ne pas se rejouer');

    // Et le service doit être de nouveau utilisable.
    await service.incrementWords(['chat']);
    expect(service.getSeenCount('chat'), 1);
    expect(await rawString(_key), isNotNull,
        reason: 'après quarantaine, les écritures doivent repartir');
  });
}
