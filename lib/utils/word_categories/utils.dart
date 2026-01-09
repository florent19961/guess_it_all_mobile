import 'dart:math';
import '../../services/word_loader_service.dart';
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

/// Générer des mots aléatoires depuis les catégories
///
/// Charge les catégories depuis JSON et génère une liste de mots uniques
/// en respectant les niveaux de difficulté sélectionnés.
Future<List<String>> generateWordsFromCategoriesAsync(
  List<String> selectedCategories,
  int count, {
  List<int>? difficultyLevels,
}) async {
  final loader = WordLoaderService();
  if (!loader.isInitialized) {
    await loader.initialize();
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

  final random = Random();
  combinedWords.shuffle(random);

  final uniqueWords = combinedWords.toSet().toList();

  return uniqueWords.take(count).toList();
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

/// Générer des mots aléatoires avec leurs métadonnées complètes
///
/// Retourne une Map<String, WordMetadata> avec les informations
/// de catégorie, difficulté et langue pour chaque mot.
Future<Map<String, WordMetadata>> generateWordsWithMetadataAsync(
  List<String> selectedCategories,
  int count, {
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

  // Collecter les mots avec leurs métadonnées
  final List<WordMetadata> allWords = [];

  for (final categoryId in categoriesToUse) {
    try {
      final category = await loader.loadCategory(categoryId);
      for (final w in category.words) {
        if (allowedLevels.contains(w.difficulty)) {
          allWords.add(WordMetadata.fromCategory(
            word: w.word,
            categoryId: categoryId,
            difficulty: w.difficulty,
            language: w.language,
          ));
        }
      }
    } catch (e) {
      print('Erreur chargement catégorie $categoryId: $e');
    }
  }

  // Mélanger
  allWords.shuffle(Random());

  // Dédupliquer et limiter
  final Map<String, WordMetadata> result = {};
  for (final meta in allWords) {
    if (!result.containsKey(meta.word) && result.length < count) {
      result[meta.word] = meta;
    }
  }

  return result;
}
