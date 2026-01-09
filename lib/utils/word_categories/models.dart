class WordWithDifficulty {
  final String word;
  final int difficulty; // 1=facile, 2=moyen, 3=difficile, 4=astronomique
  final String language; // 'international', 'fr', 'en', etc.

  const WordWithDifficulty(this.word, {this.difficulty = 2, this.language = 'international'});

  // Factory constructor depuis JSON
  factory WordWithDifficulty.fromJson(Map<String, dynamic> json) {
    return WordWithDifficulty(
      json['word'] as String,
      difficulty: json['difficulty'] as int? ?? 2,
      language: json['language'] as String? ?? 'international',
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() => {
    'word': word,
    'difficulty': difficulty,
    'language': language,
  };
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

  // Factory constructor depuis JSON
  factory WordCategory.fromJson(Map<String, dynamic> json) {
    return WordCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      words: (json['words'] as List<dynamic>)
          .map((w) => WordWithDifficulty.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'words': words.map((w) => w.toJson()).toList(),
  };
}
