import '../utils/constants.dart';
import 'fiesta/fiesta_state.dart';

class HistoryEntry {
  final int round;
  final int turn;
  final String teamId;
  final String playerId;
  final List<String> wordsGuessed;
  final List<String> wordsInvalidated;
  final List<String> wordsPassed;
  final int timeSpent;
  final bool isBonusContinuation;

  HistoryEntry({
    required this.round,
    required this.turn,
    required this.teamId,
    required this.playerId,
    required this.wordsGuessed,
    required this.wordsInvalidated,
    required this.wordsPassed,
    required this.timeSpent,
    this.isBonusContinuation = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'turn': turn,
      'teamId': teamId,
      'playerId': playerId,
      'wordsGuessed': wordsGuessed,
      'wordsInvalidated': wordsInvalidated,
      'wordsPassed': wordsPassed,
      'timeSpent': timeSpent,
      'isBonusContinuation': isBonusContinuation,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      // Chaque champ a un défaut : une entrée d'historique incomplète ne doit
      // pas rendre illisible la partie en cours tout entière.
      round: json['round'] as int? ?? 0,
      turn: json['turn'] as int? ?? 0,
      teamId: json['teamId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      wordsGuessed:
          (json['wordsGuessed'] as List<dynamic>?)?.cast<String>() ?? [],
      wordsInvalidated:
          (json['wordsInvalidated'] as List<dynamic>?)?.cast<String>() ?? [],
      wordsPassed:
          (json['wordsPassed'] as List<dynamic>?)?.cast<String>() ?? [],
      timeSpent: json['timeSpent'] as int? ?? 0,
      isBonusContinuation: json['isBonusContinuation'] as bool? ?? false,
    );
  }
}

class GameState {
  String? gameId; // UUID v4 unique pour cette partie (analytics)
  String currentScreen;
  int currentRound;
  int currentTurn;
  int currentTeamIndex;
  int currentPlayerIndexInTeam;

  List<int> teamPlayOrder;
  Map<String, List<int>> playerOrderByTeam;
  int currentTurnIndex;

  List<String> allWords;
  List<String> remainingWords;
  String? currentWord;

  List<String> wordsGuessedThisTurn;
  List<String> passedWordsThisTurn;
  String? expiredWord;
  int timeRemaining;
  int? turnBonusTime;

  int? turnStartTimestamp;
  int? turnEndTimestamp;

  /// Reste gelé, en SECONDES arrondies au supérieur.
  ///
  /// 🔴 Champ HISTORIQUE : c'est le format présent sur les téléphones des
  /// joueurs. On ne peut pas changer son unité — une partie en pause déjà
  /// persistée relirait 30 ms au lieu de 30 s. Il n'est plus l'autorité : voir
  /// [pausedRemainingMs].
  int? pausedTimeRemaining;

  /// Reste gelé, en MILLISECONDES exactes — l'autorité.
  ///
  /// 🔴 Sans lui, geler puis reprendre RENDAIT du temps au joueur : le reste
  /// était arrondi à la seconde supérieure pour être persisté, puis relu comme
  /// des millisecondes. Une pause à 29 001 ms repartait à 30 000 ms, et ouvrir
  /// puis fermer un dialogue en boucle allongeait le tour sans limite.
  int? pausedRemainingMs;

  bool isGameSuspended;
  String? suspendedScreen;

  List<HistoryEntry> history;
  int? pendingBonusTurnId; // Tour en attente de fusion après bonus time
  Map<String, dynamic>?
      preValidationSnapshot; // Snapshot pour restauration après validation
  List<String>?
      restoredValidatedWords; // Mots validés à restaurer lors du retour en arrière

  /// État Fiesta, gelé au lancement. 🔴 Nul = partie Classique ; absent du
  /// JSON quand nul, pour que le blob d'une partie Classique ne change pas.
  FiestaState? fiesta;

  GameState({
    this.gameId,
    this.currentScreen = AppConstants.screenHome,
    this.currentRound = 1,
    this.currentTurn = 1,
    this.currentTeamIndex = 0,
    this.currentPlayerIndexInTeam = 0,
    List<int>? teamPlayOrder,
    Map<String, List<int>>? playerOrderByTeam,
    this.currentTurnIndex = 0,
    List<String>? allWords,
    List<String>? remainingWords,
    this.currentWord,
    List<String>? wordsGuessedThisTurn,
    List<String>? passedWordsThisTurn,
    this.expiredWord,
    this.timeRemaining = AppConstants.defaultTurnDuration,
    this.turnBonusTime,
    this.turnStartTimestamp,
    this.turnEndTimestamp,
    this.pausedTimeRemaining,
    this.pausedRemainingMs,
    this.isGameSuspended = false,
    this.suspendedScreen,
    List<HistoryEntry>? history,
    this.pendingBonusTurnId,
    this.preValidationSnapshot,
    this.restoredValidatedWords,
    this.fiesta,
  })  : teamPlayOrder = teamPlayOrder ?? [],
        playerOrderByTeam = playerOrderByTeam ?? {},
        allWords = allWords ?? [],
        remainingWords = remainingWords ?? [],
        wordsGuessedThisTurn = wordsGuessedThisTurn ?? [],
        passedWordsThisTurn = passedWordsThisTurn ?? [],
        history = history ?? [];

  factory GameState.initial() {
    return GameState();
  }

  GameState copyWith({
    String? gameId,
    bool clearGameId = false,
    String? currentScreen,
    int? currentRound,
    int? currentTurn,
    int? currentTeamIndex,
    int? currentPlayerIndexInTeam,
    List<int>? teamPlayOrder,
    Map<String, List<int>>? playerOrderByTeam,
    int? currentTurnIndex,
    List<String>? allWords,
    List<String>? remainingWords,
    String? currentWord,
    bool clearCurrentWord = false,
    List<String>? wordsGuessedThisTurn,
    List<String>? passedWordsThisTurn,
    String? expiredWord,
    bool clearExpiredWord = false,
    int? timeRemaining,
    int? turnBonusTime,
    bool clearTurnBonusTime = false,
    int? turnStartTimestamp,
    bool clearTurnStartTimestamp = false,
    int? turnEndTimestamp,
    bool clearTurnEndTimestamp = false,
    int? pausedTimeRemaining,
    bool clearPausedTimeRemaining = false,
    int? pausedRemainingMs,
    bool clearPausedRemainingMs = false,
    bool? isGameSuspended,
    String? suspendedScreen,
    bool clearSuspendedScreen = false,
    List<HistoryEntry>? history,
    int? pendingBonusTurnId,
    bool clearPendingBonusTurnId = false,
    Map<String, dynamic>? preValidationSnapshot,
    bool clearPreValidationSnapshot = false,
    List<String>? restoredValidatedWords,
    bool clearRestoredValidatedWords = false,
    FiestaState? fiesta,
    bool clearFiesta = false,
  }) {
    return GameState(
      gameId: clearGameId ? null : (gameId ?? this.gameId),
      currentScreen: currentScreen ?? this.currentScreen,
      currentRound: currentRound ?? this.currentRound,
      currentTurn: currentTurn ?? this.currentTurn,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      currentPlayerIndexInTeam:
          currentPlayerIndexInTeam ?? this.currentPlayerIndexInTeam,
      teamPlayOrder: teamPlayOrder ?? List.from(this.teamPlayOrder),
      playerOrderByTeam: playerOrderByTeam ??
          Map.from(this.playerOrderByTeam.map(
                (key, value) => MapEntry(key, List<int>.from(value)),
              )),
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      allWords: allWords ?? List.from(this.allWords),
      remainingWords: remainingWords ?? List.from(this.remainingWords),
      currentWord: clearCurrentWord ? null : (currentWord ?? this.currentWord),
      wordsGuessedThisTurn:
          wordsGuessedThisTurn ?? List.from(this.wordsGuessedThisTurn),
      passedWordsThisTurn:
          passedWordsThisTurn ?? List.from(this.passedWordsThisTurn),
      expiredWord: clearExpiredWord ? null : (expiredWord ?? this.expiredWord),
      timeRemaining: timeRemaining ?? this.timeRemaining,
      turnBonusTime:
          clearTurnBonusTime ? null : (turnBonusTime ?? this.turnBonusTime),
      turnStartTimestamp: clearTurnStartTimestamp
          ? null
          : (turnStartTimestamp ?? this.turnStartTimestamp),
      turnEndTimestamp: clearTurnEndTimestamp
          ? null
          : (turnEndTimestamp ?? this.turnEndTimestamp),
      pausedTimeRemaining: clearPausedTimeRemaining
          ? null
          : (pausedTimeRemaining ?? this.pausedTimeRemaining),
      pausedRemainingMs: clearPausedRemainingMs
          ? null
          : (pausedRemainingMs ?? this.pausedRemainingMs),
      isGameSuspended: isGameSuspended ?? this.isGameSuspended,
      suspendedScreen: clearSuspendedScreen
          ? null
          : (suspendedScreen ?? this.suspendedScreen),
      history: history ?? List.from(this.history),
      pendingBonusTurnId: clearPendingBonusTurnId
          ? null
          : (pendingBonusTurnId ?? this.pendingBonusTurnId),
      preValidationSnapshot: clearPreValidationSnapshot
          ? null
          : (preValidationSnapshot ?? this.preValidationSnapshot),
      restoredValidatedWords: clearRestoredValidatedWords
          ? null
          : (restoredValidatedWords ?? this.restoredValidatedWords),
      fiesta: clearFiesta ? null : (fiesta ?? this.fiesta),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'currentScreen': currentScreen,
      'currentRound': currentRound,
      'currentTurn': currentTurn,
      'currentTeamIndex': currentTeamIndex,
      'currentPlayerIndexInTeam': currentPlayerIndexInTeam,
      'teamPlayOrder': teamPlayOrder,
      'playerOrderByTeam': playerOrderByTeam,
      'currentTurnIndex': currentTurnIndex,
      'allWords': allWords,
      'remainingWords': remainingWords,
      'currentWord': currentWord,
      'wordsGuessedThisTurn': wordsGuessedThisTurn,
      'passedWordsThisTurn': passedWordsThisTurn,
      'expiredWord': expiredWord,
      'timeRemaining': timeRemaining,
      'turnBonusTime': turnBonusTime,
      'turnStartTimestamp': turnStartTimestamp,
      'turnEndTimestamp': turnEndTimestamp,
      'pausedTimeRemaining': pausedTimeRemaining,
      'pausedRemainingMs': pausedRemainingMs,
      'isGameSuspended': isGameSuspended,
      'suspendedScreen': suspendedScreen,
      'history': history.map((e) => e.toJson()).toList(),
      'pendingBonusTurnId': pendingBonusTurnId,
      'preValidationSnapshot': preValidationSnapshot,
      'restoredValidatedWords': restoredValidatedWords,
      // Pas de clé `fiesta: null` : absent = Classique, et le blob d'une
      // partie Classique reste octet pour octet celui d'avant.
      if (fiesta != null) 'fiesta': fiesta!.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      gameId: json['gameId'] as String?,
      currentScreen:
          json['currentScreen'] as String? ?? AppConstants.screenHome,
      currentRound: json['currentRound'] as int? ?? 1,
      currentTurn: json['currentTurn'] as int? ?? 1,
      currentTeamIndex: json['currentTeamIndex'] as int? ?? 0,
      currentPlayerIndexInTeam: json['currentPlayerIndexInTeam'] as int? ?? 0,
      teamPlayOrder:
          (json['teamPlayOrder'] as List<dynamic>?)?.cast<int>() ?? [],
      playerOrderByTeam:
          (json['playerOrderByTeam'] as Map<String, dynamic>?)?.map(
                (key, value) =>
                    MapEntry(key, (value as List<dynamic>).cast<int>()),
              ) ??
              {},
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
      allWords: (json['allWords'] as List<dynamic>?)?.cast<String>() ?? [],
      remainingWords:
          (json['remainingWords'] as List<dynamic>?)?.cast<String>() ?? [],
      currentWord: json['currentWord'] as String?,
      wordsGuessedThisTurn:
          (json['wordsGuessedThisTurn'] as List<dynamic>?)?.cast<String>() ??
              [],
      passedWordsThisTurn:
          (json['passedWordsThisTurn'] as List<dynamic>?)?.cast<String>() ?? [],
      expiredWord: json['expiredWord'] as String?,
      timeRemaining:
          json['timeRemaining'] as int? ?? AppConstants.defaultTurnDuration,
      turnBonusTime: json['turnBonusTime'] as int?,
      turnStartTimestamp: json['turnStartTimestamp'] as int?,
      turnEndTimestamp: json['turnEndTimestamp'] as int?,
      pausedTimeRemaining: json['pausedTimeRemaining'] as int?,
      pausedRemainingMs: json['pausedRemainingMs'] as int?,
      isGameSuspended: json['isGameSuspended'] as bool? ?? false,
      suspendedScreen: json['suspendedScreen'] as String?,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingBonusTurnId: json['pendingBonusTurnId'] as int?,
      preValidationSnapshot:
          json['preValidationSnapshot'] as Map<String, dynamic>?,
      restoredValidatedWords:
          (json['restoredValidatedWords'] as List<dynamic>?)?.cast<String>(),
      // Un `fiesta` qui n'est pas un objet, ou illisible, donne une partie
      // Classique : jamais un crash.
      fiesta: json['fiesta'] is Map
          ? FiestaState.tryFromJson(
              Map<String, dynamic>.from(json['fiesta'] as Map))
          : null,
    );
  }
}
