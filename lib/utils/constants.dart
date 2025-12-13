class AppConstants {
  // Game settings defaults
  static const int defaultNumberOfTeams = 2;
  static const int defaultNumberOfPlayers = 6;
  static const int defaultWordsPerPlayer = 7;
  static const int defaultTurnDuration = 30;
  static const int defaultPassPenalty = 5;

  // Settings limits
  static const int minTeams = 2;
  static const int maxTeams = 4;
  static const int minPlayers = 4;
  static const int maxPlayers = 20;
  static const int minWordsPerPlayer = 4;
  static const int maxWordsPerPlayer = 10;
  static const int minTurnDuration = 20;
  static const int maxTurnDuration = 60;
  static const int minPassPenalty = 0;
  static const int maxPassPenalty = 10;

  // Timer
  static const int countdownDuration = 3;
  static const int timerRefreshMs = 100;

  // Storage keys
  static const String settingsKey = 'guessItAll_settings';
  static const String gameSessionKey = 'guessItAll_gameSession';
  static const String gameStateKey = 'guessItAll_gameState';

  // Screen names
  static const String screenHome = 'home';
  static const String screenSettings = 'settings';
  static const String screenRules = 'rules';
  static const String screenPlayers = 'players';
  static const String screenWords = 'words';
  static const String screenTeams = 'teams';
  static const String screenGame = 'game';
  static const String screenCountdown = 'countdown';
  static const String screenTurn = 'turn';
  static const String screenVerification = 'verification';
  static const String screenTransition = 'transition';
  static const String screenResults = 'results';
  static const String screenStats = 'stats';
  static const String screenCategories = 'categories';

  // Word choice modes
  static const String wordChoiceCustom = 'Personnalisé';
  static const String wordChoiceRandom = 'Aléatoire';

  // Default categories
  static const List<String> defaultCategories = [
    '7eme_art',
    'geographie',
    'nature',
    'metiers_sports',
    'celebrites',
    'noms_communs',
    'univers_arcade',
    'expressions',
    'dictionnaire',
    'musique',
    //'metro_parisien',
    'marques',
    'medecine',
  ];

  // Difficulty levels
  static const int difficultyEasy = 1;
  static const int difficultyMedium = 2;
  static const int difficultyHard = 3;

  static const Map<int, String> difficultyLabels = {
    1: 'Facile',
    2: 'Moyen',
    3: 'Difficile',
  };

  static const List<int> defaultDifficultyLevels = [1, 2]; // Facile + Moyen

  // Round modes
  static const Map<int, String> roundModes = {
    1: 'Description libre',
    2: 'Un seul mot',
    3: 'Mime',
  };

  static const Map<int, String> roundDescriptions = {
    1: 'Décrivez le mot avec autant de mots que vous voulez',
    2: 'Un seul mot pour faire deviner',
    3: 'Mimez sans parler !',
  };
}
