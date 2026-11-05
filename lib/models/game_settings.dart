import '../utils/constants.dart';
import 'fiesta/fiesta_rules.dart';
import 'fiesta/modifier_catalog.dart';

class GameSettings {
  int numberOfTeams;
  int numberOfPlayers;
  String wordChoice;
  int totalWords;
  int turnDuration;
  int passPenalty;
  List<String> selectedCategories;
  List<int> selectedDifficultyLevels;

  /// Auto / Personnalisé (« Avancés ») : le mode pris en passant en Fiesta.
  FiestaMode fiestaMode;

  /// Dernier choix « Mode de jeu » : Fiesta (vrai) ou Classique. Relu au
  /// démarrage et à une nouvelle partie (`GameProvider._rememberedFiesta`).
  bool fiestaEnabled;

  /// Personnalisé : règles gelées d'une partie rejouée, en attente de lancement.
  /// Elles priment sur le dernier ensemble utilisé, jusqu'au lancement ou à un
  /// choix explicite (`GameProvider._rememberFiestaChoice`). Clé absente ou
  /// illisible : nul.
  FiestaRules? replayFiesta;

  GameSettings({
    this.numberOfTeams = AppConstants.defaultNumberOfTeams,
    this.numberOfPlayers = AppConstants.defaultNumberOfPlayers,
    this.wordChoice = AppConstants.wordChoiceRandom,
    this.totalWords = AppConstants.defaultTotalWords,
    this.turnDuration = AppConstants.defaultTurnDuration,
    this.passPenalty = AppConstants.defaultPassPenalty,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
    this.fiestaMode = FiestaMode.auto,
    this.fiestaEnabled = false,
    this.replayFiesta,
  })  : selectedCategories =
            selectedCategories ?? List.from(AppConstants.defaultCategories),
        selectedDifficultyLevels = selectedDifficultyLevels ??
            List.from(AppConstants.defaultDifficultyLevels);

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
    FiestaMode? fiestaMode,
    bool? fiestaEnabled,
    FiestaRules? replayFiesta,
    bool clearReplayFiesta = false,
  }) {
    return GameSettings(
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      wordChoice: wordChoice ?? this.wordChoice,
      totalWords: totalWords ?? this.totalWords,
      turnDuration: turnDuration ?? this.turnDuration,
      passPenalty: passPenalty ?? this.passPenalty,
      selectedCategories:
          selectedCategories ?? List.from(this.selectedCategories),
      selectedDifficultyLevels:
          selectedDifficultyLevels ?? List.from(this.selectedDifficultyLevels),
      fiestaMode: fiestaMode ?? this.fiestaMode,
      fiestaEnabled: fiestaEnabled ?? this.fiestaEnabled,
      replayFiesta:
          clearReplayFiesta ? null : replayFiesta ?? this.replayFiesta,
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
      'fiestaMode': fiestaMode.name,
      'fiestaEnabled': fiestaEnabled,
      if (replayFiesta != null) 'replayFiesta': replayFiesta!.toJson(),
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      numberOfTeams:
          json['numberOfTeams'] as int? ?? AppConstants.defaultNumberOfTeams,
      numberOfPlayers: json['numberOfPlayers'] as int? ??
          AppConstants.defaultNumberOfPlayers,
      wordChoice:
          json['wordChoice'] as String? ?? AppConstants.wordChoiceRandom,
      totalWords: json['totalWords'] as int? ?? AppConstants.defaultTotalWords,
      turnDuration:
          json['turnDuration'] as int? ?? AppConstants.defaultTurnDuration,
      passPenalty:
          json['passPenalty'] as int? ?? AppConstants.defaultPassPenalty,
      selectedCategories:
          (json['selectedCategories'] as List<dynamic>?)?.cast<String>() ??
              List.from(AppConstants.defaultCategories),
      selectedDifficultyLevels:
          (json['selectedDifficultyLevels'] as List<dynamic>?)?.cast<int>() ??
              List.from(AppConstants.defaultDifficultyLevels),
      // Clé absente (réglages d'avant) ou valeur inconnue : Auto.
      fiestaMode: enumFromJson(FiestaMode.values, json['fiestaMode']) ??
          FiestaMode.auto,
      // Clé absente (réglages d'avant) ou mal typée : Classique.
      fiestaEnabled: json['fiestaEnabled'] == true,
      replayFiesta: json['replayFiesta'] is Map
          ? FiestaRules.tryFromJson(
              Map<String, dynamic>.from(json['replayFiesta'] as Map))
          : null,
    );
  }
}
