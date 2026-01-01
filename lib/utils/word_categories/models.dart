class WordWithDifficulty {
  final String word;
  final int difficulty; // 1=facile, 2=moyen, 3=difficile

  const WordWithDifficulty(this.word, {this.difficulty = 2});
}

class WordCategory {
  final String id;
  final String name;
  final String icon;
  final List<WordWithDifficulty> words;

  const WordCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
  });
}
