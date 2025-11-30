import '../utils/constants.dart';

class GameSettings {
  int numberOfTeams;
  int numberOfPlayers;
  String wordChoice;
  int wordsPerPlayer;
  int turnDuration;
  int passPenalty;
  List<String> selectedCategories;

  GameSettings({
    this.numberOfTeams = AppConstants.defaultNumberOfTeams,
    this.numberOfPlayers = AppConstants.defaultNumberOfPlayers,
    this.wordChoice = AppConstants.wordChoiceCustom,
    this.wordsPerPlayer = AppConstants.defaultWordsPerPlayer,
    this.turnDuration = AppConstants.defaultTurnDuration,
    this.passPenalty = AppConstants.defaultPassPenalty,
    List<String>? selectedCategories,
  }) : selectedCategories = selectedCategories ?? List.from(AppConstants.defaultCategories);

  factory GameSettings.initial() {
    return GameSettings();
  }

  GameSettings copyWith({
    int? numberOfTeams,
    int? numberOfPlayers,
    String? wordChoice,
    int? wordsPerPlayer,
    int? turnDuration,
    int? passPenalty,
    List<String>? selectedCategories,
  }) {
    return GameSettings(
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      wordChoice: wordChoice ?? this.wordChoice,
      wordsPerPlayer: wordsPerPlayer ?? this.wordsPerPlayer,
      turnDuration: turnDuration ?? this.turnDuration,
      passPenalty: passPenalty ?? this.passPenalty,
      selectedCategories: selectedCategories ?? List.from(this.selectedCategories),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfTeams': numberOfTeams,
      'numberOfPlayers': numberOfPlayers,
      'wordChoice': wordChoice,
      'wordsPerPlayer': wordsPerPlayer,
      'turnDuration': turnDuration,
      'passPenalty': passPenalty,
      'selectedCategories': selectedCategories,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      numberOfTeams: json['numberOfTeams'] as int? ?? AppConstants.defaultNumberOfTeams,
      numberOfPlayers: json['numberOfPlayers'] as int? ?? AppConstants.defaultNumberOfPlayers,
      wordChoice: json['wordChoice'] as String? ?? AppConstants.wordChoiceCustom,
      wordsPerPlayer: json['wordsPerPlayer'] as int? ?? AppConstants.defaultWordsPerPlayer,
      turnDuration: json['turnDuration'] as int? ?? AppConstants.defaultTurnDuration,
      passPenalty: json['passPenalty'] as int? ?? AppConstants.defaultPassPenalty,
      selectedCategories: (json['selectedCategories'] as List<dynamic>?)?.cast<String>() ??
          List.from(AppConstants.defaultCategories),
    );
  }
}
