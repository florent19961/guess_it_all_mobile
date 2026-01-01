import 'dart:math';
import 'models.dart';
import 'registry.dart';

List<WordCategory> getCategoryList() {
  return wordCategories.values.toList();
}

List<String> generateWordsFromCategories(
  List<String> selectedCategories,
  int count, {
  List<int>? difficultyLevels,
}) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3];

  final List<String> combinedWords = [];
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    }
  }

  final random = Random();
  combinedWords.shuffle(random);

  final uniqueWords = combinedWords.toSet().toList();

  return uniqueWords.take(count).toList();
}

int getTotalWordsCount(List<String> selectedCategories, {List<int>? difficultyLevels}) {
  final categoriesToUse = selectedCategories.isNotEmpty
      ? selectedCategories
      : wordCategories.keys.toList();

  final allowedLevels = difficultyLevels ?? [1, 2, 3];

  final Set<String> combinedWords = {};
  for (final categoryId in categoriesToUse) {
    final category = wordCategories[categoryId];
    if (category != null) {
      combinedWords.addAll(
        category.words
            .where((w) => allowedLevels.contains(w.difficulty))
            .map((w) => w.word),
      );
    }
  }

  return combinedWords.length;
}
