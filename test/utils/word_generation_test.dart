import 'package:flutter_test/flutter_test.dart';
import 'package:guess_it_all_mobile/services/word_history_service.dart';
import 'package:guess_it_all_mobile/utils/word_categories/utils.dart';

import '../helpers/test_prefs.dart';

void main() {
  setUp(() async {
    await givenPrefs();
    await WordHistoryService().initialize();
    await WordHistoryService().clearHistory();
  });

  test('les mots exclus ne sortent jamais du tirage', () async {
    // 🔴 C'est le contrat qui remplace la boucle « tirer un mot, le rejeter,
    // recommencer jusqu'à 100 fois ». Sans lui, remplir 10 champs vides
    // coûtait jusqu'à 1 000 scans complets du corpus sur l'isolate de l'UI.
    final premier = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      30,
      difficultyLevels: const [1, 2, 3, 4],
    );
    expect(premier, isNotEmpty, reason: 'la catégorie doit se charger');

    final interdits = premier.take(10).toSet();
    final second = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      30,
      difficultyLevels: const [1, 2, 3, 4],
      exclude: interdits,
    );

    for (final mot in second) {
      expect(interdits.contains(mot), isFalse,
          reason: '« $mot » était exclu et sort quand même');
    }
  });

  test('l\'exclusion est insensible à la casse', () async {
    final tirage = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      5,
      difficultyLevels: const [1, 2, 3, 4],
    );
    final cible = tirage.first;

    final second = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      200,
      difficultyLevels: const [1, 2, 3, 4],
      exclude: {cible.toUpperCase()},
    );

    expect(second.map((w) => w.toLowerCase()).contains(cible.toLowerCase()),
        isFalse,
        reason: 'les mots saisis par un joueur n\'ont pas la casse du corpus');
  });

  test('un tirage rend des mots tous distincts', () async {
    // La contrepartie du passage à « N mots en un appel » : c'est le générateur
    // qui garantit désormais l'unicité, plus l'appelant.
    final tirage = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      40,
      difficultyLevels: const [1, 2, 3, 4],
    );

    expect(tirage.toSet().length, tirage.length);
  });

  test('exclure tout ne lève pas, ça rend une liste vide', () async {
    final tout = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      10000,
      difficultyLevels: const [1, 2, 3, 4],
    );

    final rien = await generateWordsFromCategoriesAsync(
      const ['expressions'],
      5,
      difficultyLevels: const [1, 2, 3, 4],
      exclude: tout.toSet(),
    );

    expect(rien, isEmpty);
  });
}
