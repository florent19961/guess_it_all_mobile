import '../../services/word_loader_service.dart';
import '../../services/word_history_service.dart';
import '../../models/category_metadata.dart';
import '../../models/word_stats.dart';

/// Obtenir la liste des catégories (métadonnées uniquement)
///
/// Version asynchrone qui utilise WordLoaderService.
/// Retourne les métadonnées sans charger les mots.
Future<List<CategoryMetadata>> getCategoryListAsync() async {
  final loader = WordLoaderService();
  if (!loader.isInitialized) {
    await loader.initialize();
  }
  return loader.getCategoriesMetadata();
}

/// Générer des mots depuis les catégories avec priorité aux mots jamais vus
///
/// Charge les catégories depuis JSON et génère une liste de mots en
/// priorisant ceux que l'utilisateur n'a jamais vus (seenCount = 0),
/// puis ceux avec le compteur le plus bas.
Future<List<String>> generateWordsFromCategoriesAsync(
  List<String> selectedCategories,
  int count, {
  List<int>? difficultyLevels,
}) async {
  final loader = WordLoaderService();
  final historyService = WordHistoryService();

  if (!loader.isInitialized) {
    await loader.initialize();
  }
  if (!historyService.isInitialized) {
    await historyService.initialize();
  }

  // Charger les catégories sélectionnées
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : loader.getCategoriesMetadata().map((m) => m.id).toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3, 4];

  final List<String> combinedWords = [];

  for (final categoryId in categoriesToUse) {
    try {
      final category = await loader.loadCategory(categoryId);
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    } catch (e) {
      print('Erreur chargement catégorie $categoryId: $e');
    }
  }

  // Dédupliquer
  final uniqueWords = combinedWords.toSet().toList();

  // Sélection prioritaire (mots jamais vus d'abord)
  return historyService.selectWordsByPriority(uniqueWords, count);
}

/// Compter le nombre total de mots disponibles
///
/// Charge les catégories sélectionnées et compte le nombre total de mots uniques
/// en respectant les niveaux de difficulté.
Future<int> getTotalWordsCountAsync(
  List<String> selectedCategories, {
  List<int>? difficultyLevels,
}) async {
  final loader = WordLoaderService();
  if (!loader.isInitialized) {
    await loader.initialize();
  }

  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : loader.getCategoriesMetadata().map((m) => m.id).toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3, 4];

  final Set<String> combinedWords = {};

  for (final categoryId in categoriesToUse) {
    try {
      final category = await loader.loadCategory(categoryId);
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    } catch (e) {
      print('Erreur chargement catégorie $categoryId: $e');
    }
  }

  return combinedWords.length;
}

/// Générer des mots avec leurs métadonnées en priorisant les mots jamais vus
///
/// Retourne une Map<String, WordMetadata> avec les informations
/// de catégorie, difficulté et langue pour chaque mot.
/// Les mots jamais vus par l'utilisateur sont sélectionnés en priorité.
Future<Map<String, WordMetadata>> generateWordsWithMetadataAsync(
  List<String> selectedCategories,
  int count, {
  List<int>? difficultyLevels,
}) async {
  final loader = WordLoaderService();
  final historyService = WordHistoryService();

  if (!loader.isInitialized) {
    await loader.initialize();
  }
  if (!historyService.isInitialized) {
    await historyService.initialize();
  }

  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : loader.getCategoriesMetadata().map((m) => m.id).toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3, 4];

  // Collecter les mots avec leurs métadonnées (dédupliqués)
  final Map<String, WordMetadata> allWordsMap = {};

  for (final categoryId in categoriesToUse) {
    try {
      final category = await loader.loadCategory(categoryId);
      for (final w in category.words) {
        if (allowedLevels.contains(w.difficulty)) {
          // Garder la première occurrence pour déduplication
          if (!allWordsMap.containsKey(w.word)) {
            allWordsMap[w.word] = WordMetadata.fromCategory(
              word: w.word,
              categoryId: categoryId,
              difficulty: w.difficulty,
              language: w.language,
            );
          }
        }
      }
    } catch (e) {
      print('Erreur chargement catégorie $categoryId: $e');
    }
  }

  // Sélection prioritaire (mots jamais vus d'abord)
  final allWordsList = allWordsMap.keys.toList();
  final selectedWords = historyService.selectWordsByPriority(allWordsList, count);

  // Construire le résultat avec les métadonnées
  final Map<String, WordMetadata> result = {};
  for (final word in selectedWords) {
    result[word] = allWordsMap[word]!;
  }

  return result;
}
