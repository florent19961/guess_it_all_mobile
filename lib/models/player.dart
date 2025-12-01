class Player {
  static int _counter = 0;

  final String id;
  String name;
  List<String> words;

  Player({
    required this.id,
    required this.name,
    List<String>? words,
  }) : words = words ?? [];

  factory Player.create(String name) {
    _counter++;
    return Player(
      id: 'player-${DateTime.now().millisecondsSinceEpoch}-$_counter',
      name: name,
      words: [],
    );
  }

  Player copyWith({
    String? id,
    String? name,
    List<String>? words,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      words: words ?? List.from(this.words),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'words': words,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      words: (json['words'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() => 'Player(id: $id, name: $name, words: ${words.length})';
}
