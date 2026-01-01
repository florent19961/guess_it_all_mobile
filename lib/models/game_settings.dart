import '../utils/constants.dart';

class GameSettings {
  int numberOfTeams;
  int numberOfPlayers;
  String wordChoice;
  int totalWords;
  int turnDuration;
  int passPenalty;
  List<String> selectedCategories;
  List<int> selectedDifficultyLevels;

  GameSettings({
    this.numberOfTeams = AppConstants.defaultNumberOfTeams,
    this.numberOfPlayers = AppConstants.defaultNumberOfPlayers,
    this.wordChoice = AppConstants.wordChoiceRandom,
    this.totalWords = AppConstants.defaultTotalWords,
    this.turnDuration = AppConstants.defaultTurnDuration,
    this.passPenalty = AppConstants.defaultPassPenalty,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
  }) : selectedCategories = selectedCategories ?? List.from(AppConstants.defaultCategories),
       selectedDifficultyLevels = selectedDifficultyLevels ?? List.from(AppConstants.defaultDifficultyLevels);

  factory GameSettings.initial() {
    return GameSettings();
  }

  GameSettings copyWith({
    int? numberOfTeams,
    int? numberOfPlayers,
    String? wordChoice,
    int? totalWords,
    int? turnDuration,
    int? passPenalty,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
  }) {
    return GameSettings(
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      wordChoice: wordChoice ?? this.wordChoice,
      totalWords: totalWords ?? this.totalWords,
      turnDuration: turnDuration ?? this.turnDuration,
      passPenalty: passPenalty ?? this.passPenalty,
      selectedCategories: selectedCategories ?? List.from(this.selectedCategories),
      selectedDifficultyLevels: selectedDifficultyLevels ?? List.from(this.selectedDifficultyLevels),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfTeams': numberOfTeams,
      'numberOfPlayers': numberOfPlayers,
      'wordChoice': wordChoice,
      'totalWords': totalWords,
      'turnDuration': turnDuration,
      'passPenalty': passPenalty,
      'selectedCategories': selectedCategories,
      'selectedDifficultyLevels': selectedDifficultyLevels,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      numberOfTeams: json['numberOfTeams'] as int? ?? AppConstants.defaultNumberOfTeams,
      numberOfPlayers: json['numberOfPlayers'] as int? ?? AppConstants.defaultNumberOfPlayers,
      wordChoice: json['wordChoice'] as String? ?? AppConstants.wordChoiceRandom,
      totalWords: json['totalWords'] as int? ?? AppConstants.defaultTotalWords,
      turnDuration: json['turnDuration'] as int? ?? AppConstants.defaultTurnDuration,
      passPenalty: json['passPenalty'] as int? ?? AppConstants.defaultPassPenalty,
      selectedCategories: (json['selectedCategories'] as List<dynamic>?)?.cast<String>() ??
          List.from(AppConstants.defaultCategories),
      selectedDifficultyLevels: (json['selectedDifficultyLevels'] as List<dynamic>?)?.cast<int>() ??
          List.from(AppConstants.defaultDifficultyLevels),
    );
  }
}
