class Team {
  final String id;
  String name;
  List<String> playerIds;
  int score;
  List<int> scoreByRound;

  Team({
    required this.id,
    required this.name,
    List<String>? playerIds,
    this.score = 0,
    List<int>? scoreByRound,
  })  : playerIds = playerIds ?? [],
        scoreByRound = scoreByRound ?? [0, 0, 0];

  factory Team.create(int index) {
    return Team(
      id: 'team-${index + 1}',
      name: 'Équipe ${index + 1}',
      playerIds: [],
      score: 0,
      scoreByRound: [0, 0, 0],
    );
  }

  Team copyWith({
    String? id,
    String? name,
    List<String>? playerIds,
    int? score,
    List<int>? scoreByRound,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? List.from(this.playerIds),
      score: score ?? this.score,
      scoreByRound: scoreByRound ?? List.from(this.scoreByRound),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playerIds': playerIds,
      'score': score,
      'scoreByRound': scoreByRound,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      playerIds: (json['playerIds'] as List<dynamic>?)?.cast<String>() ?? [],
      score: json['score'] as int? ?? 0,
      scoreByRound: (json['scoreByRound'] as List<dynamic>?)?.cast<int>() ?? [0, 0, 0],
    );
  }

  @override
  String toString() => 'Team(id: $id, name: $name, players: ${playerIds.length}, score: $score)';
}
