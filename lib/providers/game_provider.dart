import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/fiesta_state.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/modifier_instance.dart';
import '../models/fiesta/modifier_recap.dart';
import '../models/fiesta/offers.dart';
import '../models/fiesta/round_transition.dart';
import '../models/fiesta/symmetric_draw.dart';
import '../models/fiesta/turn_effects.dart';
import '../models/fiesta/turn_time.dart';
import '../models/game_settings.dart';
import '../models/game_setup_snapshot.dart';
import '../models/game_state.dart';
import '../models/turn_clock.dart';
import '../models/game_result.dart';
import '../models/play_rotation.dart';
import '../models/turn_resolution.dart';
import '../models/word_stats.dart';
import '../services/game_history_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../utils/team_names.dart';
import '../utils/word_categories/utils.dart'
    show getCategoryListAsync, lookupWordsMetadata;

class GameProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AnalyticsService _analytics = AnalyticsService();
  final UserService _userService = UserService();
  final GameHistoryService _history = GameHistoryService();

  GameSettings _settings = GameSettings.initial();
  List<Player> _players = [];
  List<Team> _teams = [];
  GameState _game = GameState.initial();
  String? _currentEditingPlayerId;
  Map<String, WordMetadata>? _wordMetadataCache;

  // Getters
  GameSettings get settings => _settings;
  List<Player> get players => _players;
  List<Team> get teams => _teams;
  GameState get game => _game;
  bool get isFiesta => _game.fiesta != null;

  /// Choix Fiesta fait sur les Paramètres (et l'ensemble choisi en
  /// Personnalisé), en attente de `startGame` (Q10) :
  /// en mémoire seulement, jamais persisté. Nul = Classique. Une app tuée avant
  /// le lancement repart donc d'un choix vide.
  FiestaRules? _pendingFiesta;
  FiestaRules? get pendingFiesta => _pendingFiesta;
  String? get currentEditingPlayerId => _currentEditingPlayerId;

  void setPendingFiesta(FiestaRules? rules) {
    _pendingFiesta = rules;
    notifyListeners();
  }

  // Setter pour le joueur en cours d'édition
  void setCurrentEditingPlayer(String? playerId) {
    _currentEditingPlayerId = playerId;
    notifyListeners();
  }

  /// Stocke les métadonnées des mots générés (mode aléatoire)
  void setWordMetadataCache(Map<String, WordMetadata> metadata) {
    _wordMetadataCache = metadata;
  }

  // Constructor
  GameProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      // 1. Toujours charger les paramètres (permanents)
      final savedSettings = await _storage.loadSettings();
      if (savedSettings != null) {
        _settings = GameSettings.fromJson(savedSettings);
      }

      // 2. Charger la session (joueurs/équipes sans mots)
      final savedSession = await _storage.loadGameSession();
      if (savedSession != null) {
        _players = (savedSession['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
        _teams = (savedSession['teams'] as List<dynamic>?)
                ?.map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
      }

      // 3. Charger l'état de jeu si existant (partie en cours avec mots)
      final savedState = await _storage.loadGameState();
      if (savedState != null) {
        // Si on a un état de jeu, charger les joueurs AVEC leurs mots
        _players = (savedState['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            _players;
        _teams = (savedState['teams'] as List<dynamic>?)
                ?.map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList() ??
            _teams;
        _game = GameState.fromJson(savedState['game'] ?? {});
        // Partie Fiesta reprise après un kill : remettre sa config gelée en
        // attente, sinon « Retour aux équipes » + « Lancer » la relancerait en
        // Classique. Invariant : en partie, `pendingFiesta` = `fiesta?.rules`.
        _pendingFiesta = _game.fiesta?.rules;

        // 🔴 Reprendre AUSSI le tracking, pas seulement l'état de jeu. Sans ça,
        // une partie rouverte après un kill terminait sans jamais incrémenter
        // l'historique des mots — donc les mêmes mots ressortaient ensuite.
        // Durcir la boucle ne suffisait pas : il fallait durcir la REPRISE.
        final gameId = _game.gameId;
        if (gameId != null && _game.allWords.isNotEmpty) {
          await _analytics.resumeGame(gameId);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
    }
  }

  // Sauvegarde des paramètres (permanent)
  Future<void> _saveSettings() async {
    await _storage.saveSettings(_settings.toJson());
  }

  // Sauvegarde de la session (joueurs/équipes avec mots)
  Future<void> _saveGameSession() async {
    await _storage.saveGameSession({
      'players': _players.map((p) => p.toJson()).toList(),
      'teams': _teams.map((t) => t.toJson()).toList(),
    });
  }

  // Sauvegarde de l'état de jeu complet (partie en cours avec mots)
  Future<void> _saveGameState() async {
    await _storage.saveGameState({
      'players': _players.map((p) => p.toJson()).toList(),
      'teams': _teams.map((t) => t.toJson()).toList(),
      'game': _game.toJson(),
    });
  }

  // ========== ACTIONS - SETTINGS ==========

  void updateSettings({
    int? numberOfTeams,
    int? numberOfPlayers,
    String? wordChoice,
    int? totalWords,
    int? turnDuration,
    int? passPenalty,
    List<String>? selectedCategories,
    List<int>? selectedDifficultyLevels,
  }) {
    // Sauvegarder les anciennes valeurs pour détecter les changements
    final oldNumberOfTeams = _settings.numberOfTeams;
    final oldWordChoice = _settings.wordChoice;
    final oldCategories = _settings.selectedCategories;
    final oldDifficulties = _settings.selectedDifficultyLevels;

    // Mettre à jour les settings
    _settings = _settings.copyWith(
      numberOfTeams: numberOfTeams,
      numberOfPlayers: numberOfPlayers,
      wordChoice: wordChoice,
      totalWords: totalWords,
      turnDuration: turnDuration,
      passPenalty: passPenalty,
      selectedCategories: selectedCategories,
      selectedDifficultyLevels: selectedDifficultyLevels,
    );

    // Détecter les changements
    final modeChanged = wordChoice != null && wordChoice != oldWordChoice;
    final categoriesChanged = selectedCategories != null &&
        !_listEquals(selectedCategories, oldCategories);
    final difficultiesChanged = selectedDifficultyLevels != null &&
        !_listEquals(selectedDifficultyLevels, oldDifficulties);

    // Effacer les mots si :
    // 1. On change de mode (Aléatoire ↔ Personnalisé)
    // 2. OU on est en Aléatoire ET catégories/difficultés changent
    if (modeChanged ||
        (_settings.wordChoice == 'Aléatoire' &&
            (categoriesChanged || difficultiesChanged))) {
      _clearAllPlayersWords();
    }

    // Détecter le changement de nombre d'équipes
    final teamCountChanged =
        numberOfTeams != null && numberOfTeams != oldNumberOfTeams;

    // Recréer les équipes si le nombre change
    if (teamCountChanged && _teams.isNotEmpty) {
      createTeams();
    }

    notifyListeners();
    _saveSettings();
  }

  void toggleDifficultyLevel(int level) {
    final newLevels = List<int>.from(_settings.selectedDifficultyLevels);
    if (newLevels.contains(level)) {
      newLevels.remove(level);
    } else {
      newLevels.add(level);
    }
    newLevels.sort();
    updateSettings(selectedDifficultyLevels: newLevels);
  }

  // Compare deux listes
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Efface les mots de tous les joueurs
  void _clearAllPlayersWords() {
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(words: []);
    }
    _saveGameSession();
  }

  // ========== ACTIONS - PLAYERS ==========

  Map<String, dynamic> addPlayer(String name, {bool allowEmpty = false}) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty && !allowEmpty) {
      return {'error': 'Le nom est requis'};
    }

    if (trimmedName.isNotEmpty && _players.any((p) => p.name == trimmedName)) {
      return {'error': 'Ce nom existe déjà'};
    }

    final newPlayer = Player.create(trimmedName);
    _players.add(newPlayer);
    notifyListeners();
    _saveGameSession();

    return {'success': true, 'player': newPlayer};
  }

  void updatePlayer(String playerId, {String? name}) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(name: name);
      notifyListeners();
      _saveGameSession();
    }
  }

  void updatePlayerWords(String playerId, List<String> words) {
    final index = _players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      _players[index] = _players[index].copyWith(words: words);
      notifyListeners();
      _saveGameSession();
    }
  }

  void removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
    _saveGameSession();
  }

  void cleanupEmptyPlayers() {
    _players.removeWhere((p) => p.name.trim().isEmpty);
    notifyListeners();
    _saveGameSession();
  }

  // ========== ACTIONS - TEAMS ==========

  void createTeams() {
    final names = drawTeamNames(_settings.numberOfTeams);
    _teams = List.generate(
      _settings.numberOfTeams,
      (i) => Team.create(i).copyWith(name: names[i]),
    );
    notifyListeners();
    _saveGameSession();
  }

  void updateTeamName(String teamId, String newName) {
    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      _teams[index] = _teams[index].copyWith(name: newName);
      notifyListeners();
      _saveGameSession();
    }
  }

  void movePlayerToTeam(String playerId, String teamId) {
    // Retirer le joueur de toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      if (_teams[i].playerIds.contains(playerId)) {
        final newPlayerIds = List<String>.from(_teams[i].playerIds)
          ..remove(playerId);
        _teams[i] = _teams[i].copyWith(playerIds: newPlayerIds);
      }
    }

    // Ajouter à la nouvelle équipe
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      final newPlayerIds = List<String>.from(_teams[teamIndex].playerIds)
        ..add(playerId);
      _teams[teamIndex] = _teams[teamIndex].copyWith(playerIds: newPlayerIds);
    }

    notifyListeners();
    _saveGameSession();
  }

  void randomizeTeams() {
    final playersWithNames =
        _players.where((p) => p.name.trim().isNotEmpty).toList();
    final shuffledPlayers = List<Player>.from(playersWithNames)
      ..shuffle(Random());

    // Réinitialiser toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      _teams[i] = _teams[i].copyWith(playerIds: []);
    }

    // Distribuer les joueurs
    for (int i = 0; i < shuffledPlayers.length; i++) {
      final teamIndex = i % _settings.numberOfTeams;
      final newPlayerIds = List<String>.from(_teams[teamIndex].playerIds)
        ..add(shuffledPlayers[i].id);
      _teams[teamIndex] = _teams[teamIndex].copyWith(playerIds: newPlayerIds);
    }

    notifyListeners();
    _saveGameSession();
  }

  /// Synchronise les équipes avec les joueurs actuels
  /// - Supprime les joueurs invalides des équipes
  /// - Distribue les nouveaux joueurs aléatoirement dans l'équipe la plus petite
  void syncTeamsWithPlayers() {
    if (_teams.isEmpty) return;

    final validPlayerIds = _players.map((p) => p.id).toSet();
    final playersInTeams = <String>{};

    // 1. Supprimer les IDs de joueurs invalides de toutes les équipes
    for (int i = 0; i < _teams.length; i++) {
      final validIdsForTeam = _teams[i]
          .playerIds
          .where((id) => validPlayerIds.contains(id))
          .toList();
      _teams[i] = _teams[i].copyWith(playerIds: validIdsForTeam);
      playersInTeams.addAll(validIdsForTeam);
    }

    // 2. Trouver les joueurs non assignés (avec un nom)
    final unassignedPlayers = _players
        .where(
            (p) => p.name.trim().isNotEmpty && !playersInTeams.contains(p.id))
        .toList();

    // 3. Distribuer les nouveaux joueurs aléatoirement dans l'équipe la plus petite
    if (unassignedPlayers.isNotEmpty) {
      final shuffled = List<Player>.from(unassignedPlayers)..shuffle(Random());
      for (final player in shuffled) {
        // Trouver l'équipe avec le moins de joueurs
        int minIndex = 0;
        int minCount = _teams[0].playerIds.length;
        for (int i = 1; i < _teams.length; i++) {
          if (_teams[i].playerIds.length < minCount) {
            minCount = _teams[i].playerIds.length;
            minIndex = i;
          }
        }
        final newIds = List<String>.from(_teams[minIndex].playerIds)
          ..add(player.id);
        _teams[minIndex] = _teams[minIndex].copyWith(playerIds: newIds);
      }
    }

    notifyListeners();
    _saveGameSession();
  }

  // ========== ACTIONS - GAME ==========

  /// [fiesta] = configuration Fiesta à GELER dans la partie ; nul = Classique.
  ///
  /// 🔴 Le `copyWith` ci-dessous part de `_game` : sans `clearFiesta`, la
  /// config d'une partie Fiesta précédente survivrait à un lancement Classique.
  Future<void> startGame({FiestaRules? fiesta}) async {
    // Créer le pool de tous les mots
    final List<String> allWords = [];
    for (final player in _players) {
      allWords.addAll(player.words);
    }

    // Mélanger les mots
    final shuffledWords = List<String>.from(allWords)..shuffle(Random());

    // Générer l'ordre aléatoire des équipes et des joueurs
    final playOrder = _generatePlayOrder();

    // Obtenir le premier joueur
    final firstTeamIndex = playOrder['teamPlayOrder']![0];
    final firstPlayerIndex =
        playOrder['playerOrderByTeam']![_teams[firstTeamIndex].id]![0];

    // Générer un gameId unique pour cette partie
    final gameId = _userService.generateGameId();

    // Auto : « Une seule réponse » (toute la partie) est tirée ici, une fois
    // sur 4, et gelée avec le reste (relue telle quelle après un kill).
    final rules = fiesta == null || fiesta.mode != FiestaMode.auto
        ? fiesta
        : FiestaRules(
            mode: FiestaMode.auto,
            symmetric: fiesta.symmetric,
            autoCalibrate: fiesta.autoCalibrate,
            oneAnswer: drawsOneAnswer(gameId),
          );

    _game = _game.copyWith(
      gameId: gameId,
      currentScreen: AppConstants.screenGame,
      currentRound: 1,
      currentTurn: 1,
      currentTeamIndex: firstTeamIndex,
      currentPlayerIndexInTeam: firstPlayerIndex,
      teamPlayOrder: playOrder['teamPlayOrder'],
      playerOrderByTeam: playOrder['playerOrderByTeam'],
      currentTurnIndex: 0,
      allWords: shuffledWords,
      remainingWords: shuffledWords,
      currentWord: shuffledWords.isNotEmpty ? shuffledWords[0] : null,
      wordsGuessedThisTurn: [],
      passedWordsThisTurn: [],
      timeRemaining: _settings.turnDuration,
      clearTurnBonusTime: true,
      history: [],
      fiesta: rules == null
          ? null
          : FiestaState(
              rules: rules,
              active: roundModifiers(rules, gameId: gameId, round: 1),
            ),
      clearFiesta: rules == null,
    );

    // Initialiser le tracking analytics
    await _initializeAnalytics(gameId, shuffledWords);

    notifyListeners();
    _saveGameState();
  }

  /// Initialise le tracking analytics pour une nouvelle partie
  Future<void> _initializeAnalytics(String gameId, List<String> words) async {
    // Créer les métadonnées des mots
    final wordMetadata = <String, WordMetadata>{};

    // En mode aléatoire, les mots ont des métadonnées de catégorie
    // En mode personnalisé, on lie les mots aux joueurs
    if (_settings.wordChoice == AppConstants.wordChoiceRandom) {
      // Mode aléatoire : utiliser le cache de métadonnées
      // Identifier les mots absents du cache (cache null ou incomplet)
      final missingWords = _wordMetadataCache == null
          ? words
          : words.where((w) => !_wordMetadataCache!.containsKey(w)).toList();

      // Lookup direct dans les catégories pour les mots manquants
      Map<String, WordMetadata> lookedUp = {};
      if (missingWords.isNotEmpty) {
        lookedUp = await lookupWordsMetadata(missingWords);
      }

      for (final word in words) {
        if (_wordMetadataCache != null &&
            _wordMetadataCache!.containsKey(word)) {
          wordMetadata[word] = _wordMetadataCache![word]!;
        } else if (lookedUp.containsKey(word)) {
          wordMetadata[word] = lookedUp[word]!;
        } else {
          // Dernier fallback (mot vraiment introuvable)
          wordMetadata[word] = WordMetadata(word: word);
        }
      }
    } else {
      // Mode personnalisé : lier les mots aux joueurs
      for (final player in _players) {
        for (final word in player.words) {
          wordMetadata[word] = WordMetadata.custom(
            word: word,
            submittedBy: player.id,
          );
        }
      }
    }

    await _analytics.startGame(
      gameId: gameId,
      numberOfPlayers: _players.length,
      numberOfTeams: _teams.length,
      totalWords: words.length,
      turnDuration: _settings.turnDuration,
      selectedCategories: _settings.selectedCategories,
      selectedDifficultyLevels: _settings.selectedDifficultyLevels,
      wordMetadata: wordMetadata,
      // `_game.fiesta` est déjà gelé par `startGame` ; nul en Classique.
      gameMode: _game.fiesta == null ? null : fiestaModeId(_game.fiesta!.rules),
      fiestaRules: _game.fiesta?.rules.toJson(),
    );
  }

  Map<String, dynamic> _generatePlayOrder() {
    // Mélanger l'ordre des équipes
    final shuffledTeamIndices = List<int>.generate(_teams.length, (i) => i)
      ..shuffle(Random());

    // On ne stocke que LE CYCLE, pas ses répétitions : l'ordre est périodique,
    // donc il se dérive (voir play_rotation.dart). Avant, la permutation était
    // recopiée 1000 fois — ~24 000 entiers pour 4 équipes et 20 joueurs,
    // ré-écrits sur disque à chaque mot deviné.
    final Map<String, List<int>> playerOrderByTeam = {};
    for (final team in _teams) {
      playerOrderByTeam[team.id] =
          List<int>.generate(team.playerIds.length, (i) => i)
            ..shuffle(Random());
    }

    return {
      'teamPlayOrder': shuffledTeamIndices,
      'playerOrderByTeam': playerOrderByTeam,
    };
  }

  /// Durée de départ du tour à venir et son détail (carte « Temps du tour »).
  ///
  /// 🔴 SEULE source de la durée : `startTurn` (aperçu) et `startTurnTimer`
  /// (chrono) la lisent tous deux, sinon l'avant-tour annonce 30 s et le chrono
  /// part à 48. Continuation (`turnBonusTime` posé) = ses secondes, sans
  /// modificateur (Q5). En Classique : `turnBonusTime ?? turnDuration`, comme
  /// avant.
  TurnTime get turnTime {
    final fiesta = _game.fiesta;
    final due = fiesta == null || _teams.isEmpty
        ? 0
        : fiesta.catchUpDue[_teams[_game.currentTeamIndex].id] ?? 0;
    return composeTurnSeconds(
      baseSeconds: _settings.turnDuration,
      carriedSeconds: _game.turnBonusTime,
      catchUpSeconds: max(0, due),
      leaderMalusSeconds: max(0, -due),
      minus10sCount:
          currentTeamModifiers.where((m) => m.catalogId == 'minus_10s').length,
    );
  }

  void startTurn() {
    _game = _game.copyWith(
      currentScreen: AppConstants.screenCountdown,
      wordsGuessedThisTurn: [],
      passedWordsThisTurn: [],
      timeRemaining: turnTime.total,
    );

    notifyListeners();
    _saveGameState();
  }

  void startTurnTimer() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // À lire AVANT d'effacer `turnBonusTime` : c'est lui qui dit si ce tour est
    // une continuation, donc si le rattrapage s'applique et se consomme.
    final durationSeconds = turnTime.total;
    final durationMs = durationSeconds * 1000;
    var fiesta = _game.fiesta;
    // Lu seulement en Fiesta : en Classique, rien n'exige une équipe ici.
    final teamId = fiesta == null ? '' : _teams[_game.currentTeamIndex].id;
    if (fiesta != null &&
        _game.turnBonusTime == null &&
        fiesta.catchUpDue.containsKey(teamId)) {
      // Consommé une fois, effacé : même principe que `turnBonusTime`.
      fiesta = fiesta.copyWith(
          catchUpDue: Map.of(fiesta.catchUpDue)..remove(teamId));
    }
    // Bonus à charge (×2, deux mots) : la charge se dépense ICI, pas à
    // l'interrupteur. Éteindre avant le départ ou revenir en arrière n'a donc
    // rien à rendre.
    for (final id in kChargeBonusKeys.keys) {
      if (fiesta == null || fiesta.turn.charges[id] != ChargeState.armed) {
        continue;
      }
      fiesta = fiesta.copyWith(
        turn: fiesta.turn.withCharge(id, ChargeState.spent),
        chargesUsed: [
          ...fiesta.chargesUsed,
          ChargeUse(catalogId: id, teamId: teamId, round: _game.currentRound),
        ],
      );
    }
    // Carte B tirée au départ (et au départ de la continuation de fin de
    // manche, même tour). Déjà là = partie reprise : on la garde. Les deux
    // cartes restent dans `remainingWords` jusqu'à être trouvées.
    final currentWord = _game.currentWord;
    String? drawnSecond;
    if (fiesta != null &&
        fiesta.turn.charges['two_words'] == ChargeState.spent &&
        fiesta.turn.secondWord == null &&
        currentWord != null) {
      drawnSecond = drawOtherCard(
        pool: _game.remainingWords,
        passed: const [],
        other: currentWord,
      ).word;
      if (drawnSecond != null) {
        fiesta = _withSecondWord(fiesta, drawnSecond);
      }
    }

    _game = _game.copyWith(
      currentScreen: AppConstants.screenTurn,
      turnStartTimestamp: now,
      turnEndTimestamp: now + durationMs,
      clearPausedTimeRemaining: true,
      clearPausedRemainingMs: true,
      timeRemaining: durationSeconds,
      turnAllottedSeconds: durationSeconds,
      clearTurnBonusTime: true,
      // Nul en Classique : `copyWith(fiesta: null)` le laisse nul.
      fiesta: fiesta,
    );

    // Tracker l'affichage du premier mot (et de la carte B)
    _trackWordShown();
    if (drawnSecond != null) _trackWordShown(drawnSecond);

    notifyListeners();
    _saveGameState();
  }

  /// Notifie le service analytics qu'un nouveau mot est affiché : [word], ou
  /// le mot courant (carte A) par défaut.
  void _trackWordShown([String? word]) {
    final currentWord = word ?? _game.currentWord;
    if (currentWord == null || !_analytics.isTracking) return;

    _analytics.onWordShown(currentWord, _eventContext);
  }

  /// Contexte analytics du tour en cours, relu de l'état PERSISTÉ à chaque
  /// événement : il survit à un kill, y compris sur la vérification (le tour
  /// vérifié est encore le tour courant). `modifiers` nul en Classique :
  /// l'événement garde alors exactement l'ancienne forme.
  WordEventContext get _eventContext => (
        round: _game.currentRound,
        turn: _game.currentTurn,
        teamId: getCurrentTeam()?.id ?? '',
        playerId: getCurrentPlayer()?.id ?? '',
        modifiers: isFiesta
            ? [
                ...turnModifiers.map((m) => m.catalogId),
                if (isDoublePointsOn) 'double_points',
                if (isTwoWordsOn) 'two_words',
              ]
            : null,
      );

  /// [word] : la carte visée (« Deux mots à la fois »), la carte A par
  /// défaut. Un mot qui n'est plus à l'écran (tap périmé) est ignoré.
  void markWordAsGuessed([String? word]) {
    final currentWord = word ?? _game.currentWord;
    if (currentWord == null) return;
    final second = secondWord;
    if (currentWord != _game.currentWord && currentWord != second) return;

    // Tracker le mot deviné AVANT de changer l'état
    _analytics.onWordGuessed(currentWord, _eventContext);

    final newGuessedWords = List<String>.from(_game.wordsGuessedThisTurn);
    if (!newGuessedWords.contains(currentWord)) {
      newGuessedWords.add(currentWord);
    }
    final newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    // Retirer le mot de passedWordsThisTurn s'il y était (mot recyclé puis deviné)
    final newPassedWords = List<String>.from(_game.passedWordsThisTurn)
      ..remove(currentWord);

    // Mélanger les mots restants
    newRemainingWords.shuffle(Random());

    if (second != null) {
      // Deux cartes : seule la carte trouvée change, la manche continue
      // (l'autre carte est encore dans le pool).
      final cards = _cardsAfter(currentWord,
          pool: newRemainingWords, passed: newPassedWords);
      _game = _game.copyWith(
        currentWord: cards.first,
        remainingWords: cards.pool,
        wordsGuessedThisTurn: newGuessedWords,
        passedWordsThisTurn: newPassedWords,
        fiesta: _withSecondWord(_game.fiesta!, cards.second),
      );
      if (cards.drawn != null) _trackWordShown(cards.drawn);
    } else if (newRemainingWords.isEmpty) {
      // Fin de la manche si plus de mots
      // Vérifier s'il reste des mots passés à recycler
      if (newPassedWords.isNotEmpty) {
        // Remettre les mots passés dans la pile
        final restoredWords = List<String>.from(newPassedWords)
          ..shuffle(Random());
        final nextCurrentWord = restoredWords[0];

        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: restoredWords,
          currentWord: nextCurrentWord,
        );

        // Tracker le nouveau mot affiché
        _trackWordShown();
      } else {
        // Vraie fin de manche (plus aucun mot disponible ni passé).
        //
        // 🔴 Ce chemin doit ARRÊTER l'horloge et reporter le temps restant en
        // bonus, exactement comme `endTurn`. Sans ça : la deadline restait
        // vivante pendant l'écran de vérification (le ticker pouvait encore
        // déclencher `endTurn`), et le temps gagné en finissant la manche en
        // avance était simplement perdu. C'était le seul des deux chemins vers
        // l'écran de vérification à ne pas le faire.
        final now = DateTime.now().millisecondsSinceEpoch;
        final bonusSeconds = turnClock.displayedSecondsAt(now);

        _game = _game.copyWith(
          wordsGuessedThisTurn: newGuessedWords,
          passedWordsThisTurn: newPassedWords,
          remainingWords: newRemainingWords,
          clearCurrentWord: true,
          currentScreen: AppConstants.screenVerification,
          turnBonusTime: bonusSeconds,
          timeRemaining: bonusSeconds,
          clearTurnStartTimestamp: true,
          clearTurnEndTimestamp: true,
          clearPausedTimeRemaining: true,
          clearPausedRemainingMs: true,
        );
      }
    } else {
      final newCurrentWord = newRemainingWords[0];

      _game = _game.copyWith(
        currentWord: newCurrentWord,
        remainingWords: newRemainingWords,
        wordsGuessedThisTurn: newGuessedWords,
        passedWordsThisTurn: newPassedWords,
      );

      // Tracker le nouveau mot affiché
      _trackWordShown();
    }

    notifyListeners();
    _saveGameState();
  }

  /// [word] : la carte visée, comme pour [markWordAsGuessed].
  void passWord([String? word]) {
    final currentWord = word ?? _game.currentWord;
    final clock = turnClock;

    if (currentWord == null || !clock.isRunning) return;
    final second = secondWord;
    if (currentWord != _game.currentWord && currentWord != second) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Garde inchangée : elle porte sur la seconde AFFICHÉE, pas sur les ms.
    // C'est délibéré — passer avec « 5 » à l'écran et une pénalité de 5 reste
    // autorisé et met le chrono à zéro, comme avant. Comparer les ms refuserait
    // ce cas et changerait la règle du jeu en douce.
    // 🔴 Sortie AVANT `onWordPassed` : sous `no_pass`, aucune passe n'a lieu.
    if (!canPassWith(clock.displayedSecondsAt(now))) return;

    // Pénalité EFFECTIVE : 0 tant qu'il reste une passe gratuite (2-8).
    final passPenalty = currentPassPenalty;
    final fiesta = _game.fiesta;
    final usesFreePass = fiesta != null && hasFreePass;

    // Tracker le pass AVANT de changer l'état
    _analytics.onWordPassed(currentWord, _eventContext);

    // La pénalité est retirée à la deadline, en ms exactes : plus de ré-ancrage
    // sur une seconde arrondie au supérieur (qui rendait du temps à chaque passe
    // et faisait remonter le chrono à pénalité 0).
    final newClock = clock.applyPenalty(passPenalty, now);

    final newPassedWords = List<String>.from(_game.passedWordsThisTurn);
    if (!newPassedWords.contains(currentWord)) {
      newPassedWords.add(currentWord);
    }
    var newRemainingWords = List<String>.from(_game.remainingWords)
      ..remove(currentWord);

    var newFiesta = usesFreePass
        ? fiesta.copyWith(
            turn: fiesta.turn.copyWith(freePassesUsed: freePassesUsed + 1))
        : fiesta;
    String? newCurrentWord;
    String? drawn;
    if (second != null) {
      // Deux cartes : seule la carte passée change. Le recyclage se fait dans
      // `_cardsAfter`, hors de l'autre carte.
      newRemainingWords.shuffle(Random());
      final cards = _cardsAfter(currentWord,
          pool: newRemainingWords, passed: newPassedWords);
      newRemainingWords = cards.pool;
      newCurrentWord = cards.first;
      drawn = cards.drawn;
      newFiesta = _withSecondWord(newFiesta!, cards.second);
    } else {
      // Si plus de mots restants, recycler les mots passés
      if (newRemainingWords.isEmpty && newPassedWords.isNotEmpty) {
        newRemainingWords = List<String>.from(newPassedWords);
      }

      newRemainingWords.shuffle(Random());
      newCurrentWord =
          newRemainingWords.isNotEmpty ? newRemainingWords[0] : null;
      drawn = newCurrentWord;
    }

    _game = _withClock(
      _game.copyWith(
        currentWord: newCurrentWord,
        passedWordsThisTurn: newPassedWords,
        remainingWords: newRemainingWords,
        // Nul en Classique : `copyWith(fiesta: null)` le laisse nul.
        fiesta: newFiesta,
      ),
      newClock,
      nowMs: now,
    );

    // Tracker le nouveau mot affiché
    if (drawn != null) {
      _trackWordShown(drawn);
    }

    notifyListeners();
    _saveGameState();
  }

  void endTurn() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Passe par l'horloge : si le tour était GELÉ (app en arrière-plan, dialogue
    // ouvert), c'est le reste gelé qui compte — pas une deadline périmée.
    final timeRemaining = turnClock.displayedSecondsAt(now);

    // Si la manche n'est pas finie et qu'il y avait un mot en cours, le sauvegarder comme "expiré"
    final isRoundFinished = _game.remainingWords.isEmpty;
    final expiredWord = isRoundFinished ? null : _game.currentWord;

    // Deux mots : la carte B part aussi à la vérification, sous sa propre
    // clé. Touché seulement si B est à l'écran : un second `endTurn` (chrono
    // + dialogue) ne l'efface donc pas.
    final second = secondWord;
    var fiesta = _game.fiesta;
    if (second != null) {
      fiesta = _withSecondWord(fiesta!, null);
      if (!isRoundFinished) {
        fiesta = fiesta.copyWith(
            turn: fiesta.turn.copyWith(secondExpiredWord: second));
      }
    }

    // Tracker le mot expiré si applicable
    if (expiredWord != null) {
      _analytics.onWordExpired(expiredWord, _eventContext);
    }
    if (second != null && !isRoundFinished) {
      _analytics.onWordExpired(second, _eventContext);
    }

    _game = _game.copyWith(
      timeRemaining: timeRemaining,
      currentScreen: AppConstants.screenVerification,
      turnBonusTime: isRoundFinished ? timeRemaining : null,
      expiredWord: expiredWord,
      clearExpiredWord: isRoundFinished,
      fiesta: fiesta,
      clearTurnStartTimestamp: true,
      clearTurnEndTimestamp: true,
      // Purger AUSSI le gel : sinon l'horloge reste « en pause » après la fin du
      // tour, et le `then` du dialogue « Terminer le tour » la reprend — ce qui
      // ré-arme une deadline sur l'écran de vérification.
      clearPausedTimeRemaining: true,
      clearPausedRemainingMs: true,
    );

    notifyListeners();
    _saveGameState();
  }

  // ========== TEMPS DU TOUR ==========
  //
  // 🔴 `TurnClock` est la SEULE autorité sur le temps de jeu. `turnEndTimestamp`
  // et `pausedTimeRemaining` ne sont que sa forme persistée : on ne les écrit
  // jamais à la main, on passe par [_applyClock].

  /// Reconstruit l'horloge depuis l'état persisté.
  TurnClock get turnClock {
    final end = _game.turnEndTimestamp;
    if (end != null) return TurnClock.endingAt(end);

    // Les millisecondes exactes font foi. Le champ en secondes n'est relu que
    // pour une partie mise en pause par une version ANTÉRIEURE de l'app, qui
    // ne l'écrivait pas — sinon on rendrait au joueur l'arrondi au supérieur.
    final pausedMs = _game.pausedRemainingMs;
    if (pausedMs != null) return TurnClock.frozen(pausedMs);

    final pausedSeconds = _game.pausedTimeRemaining;
    if (pausedSeconds != null) return TurnClock.frozen(pausedSeconds * 1000);

    return const TurnClock.stopped();
  }

  /// Écrit [clock] dans l'état, en gardant les deux champs persistés cohérents.
  ///
  /// L'un exclut l'autre : une deadline vivante ET un reste gelé, c'est
  /// exactement l'incohérence qui faisait terminer un tour au retour d'un
  /// dialogue.
  GameState _withClock(GameState state, TurnClock clock, {required int nowMs}) {
    return state.copyWith(
      turnEndTimestamp: clock.endTimestampMs,
      clearTurnEndTimestamp: clock.endTimestampMs == null,
      // Les ms exactes sont l'autorité ; la version en secondes reste écrite
      // pour qu'un downgrade éventuel retrouve un champ qu'il sait lire.
      pausedRemainingMs: clock.frozenRemainingMs,
      clearPausedRemainingMs: !clock.isPaused,
      pausedTimeRemaining:
          clock.isPaused ? (clock.frozenRemainingMs! / 1000).ceil() : null,
      clearPausedTimeRemaining: !clock.isPaused,
      timeRemaining: clock.displayedSecondsAt(nowMs),
    );
  }

  void _applyClock(TurnClock clock, {required int nowMs, bool persist = true}) {
    _game = _withClock(_game, clock, nowMs: nowMs);
    notifyListeners();
    if (persist) _saveGameState();
  }

  /// Gèle le tour en cours (dialogue ouvert, app en arrière-plan, appel entrant).
  ///
  /// Idempotent : appelable depuis plusieurs sources sans risque de double gel.
  void pauseTurn() {
    final clock = turnClock;
    if (!clock.isRunning) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _applyClock(clock.pauseAt(now), nowMs: now);
  }

  /// Reprend le tour là où il avait été gelé.
  void resumeTurn() {
    final clock = turnClock;
    if (!clock.isPaused) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _applyClock(clock.resumeAt(now), nowMs: now);
  }

  /// Rafraîchit la seconde affichée depuis l'horloge.
  ///
  /// ⚠️ N'émet une notification que lorsque la seconde CHANGE. L'ancien code
  /// poussait une valeur dix fois par seconde et notifiait à chaque tick, ce qui
  /// reconstruisait tout l'arbre sous le `Consumer` racine 10 fois/s.
  void refreshDisplayedTime() {
    final clock = turnClock;
    if (!clock.isRunning) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = clock.displayedSecondsAt(now);
    if (seconds == _game.timeRemaining) return;

    _game = _game.copyWith(timeRemaining: seconds);
    notifyListeners();
  }

  void validateWords(List<String> validatedWords) {
    // Double tap sur « Valider » : le second appel recréditait les mots à
    // l'équipe suivante et brûlait ses cartes de tour. Seul l'écran de
    // vérification valide (même garde que `nextRound`).
    if (_game.currentScreen != AppConstants.screenVerification) return;
    final currentTeam = _teams[_game.currentTeamIndex];
    final passedWordsThisTurn = _game.passedWordsThisTurn;

    // Tout le CALCUL (classification, pool, score) vit dans `resolveTurn`, une
    // fonction pure et testée. Ne reste ici que ce qui a des effets de bord :
    // tracking analytics, mutation des équipes, avancement du tour.
    final resolution = resolveTurn(
      validatedWords: validatedWords,
      guessedThisTurn: _game.wordsGuessedThisTurn,
      passedThisTurn: passedWordsThisTurn,
      expiredWords: [
        if (_game.expiredWord != null) _game.expiredWord!,
        if (secondExpiredWord != null) secondExpiredWord!,
      ],
      currentPool: _game.remainingWords,
      pointsMultiplier: isDoublePointsOn ? 2 : 1,
    );

    final allInvalidatedWords = resolution.allInvalidated;
    final newRemainingWords = resolution.remainingPool;
    final pointsScored = resolution.pointsScored;

    // Tracker les mots invalidés pour les analytics, puis les mots
    // passed/expired validés comme guessed. Contexte lu AVANT la mutation.
    final context = _eventContext;
    for (final word in allInvalidatedWords) {
      _analytics.onWordInvalidated(word, context);
    }
    for (final word in resolution.validatedPassed) {
      _analytics.onWordValidatedAsGuessed(word, context);
    }
    for (final word in resolution.expiredValidated) {
      _analytics.onWordValidatedAsGuessed(word, context);
    }

    // Mettre à jour le score
    final teamIndex = _teams.indexWhere((t) => t.id == currentTeam.id);
    if (teamIndex != -1) {
      final team = _teams[teamIndex];
      final newScore = team.score + pointsScored;
      final scoreByRound = List<int>.from(team.scoreByRound);
      scoreByRound[_game.currentRound - 1] += pointsScored;
      _teams[teamIndex] =
          team.copyWith(score: newScore, scoreByRound: scoreByRound);
    }

    // Vérifier si on doit fusionner avec l'entrée précédente (bonus time)
    // La fusion se fait toujours quand il y a un bonus pending, même avec des mots invalidés
    final hasBonusPending = _game.pendingBonusTurnId != null;
    final shouldMergeWithPrevious = hasBonusPending && _game.history.isNotEmpty;

    // Temps passé sur ce tour : sur sa durée de DÉPART réelle, pas sur le
    // réglage — une continuation de 7 s finie à 2 s comptait 28 s. Nul sur une
    // partie reprise d'une version antérieure : comportement d'alors.
    final currentTimeSpent =
        (_game.turnAllottedSeconds ?? _settings.turnDuration) -
            _game.timeRemaining;

    List<HistoryEntry> newHistory;
    int nextTurn;

    if (shouldMergeWithPrevious) {
      // Créer une entrée séparée pour le bonus time (pas de fusion)
      // Cela permet d'attribuer les mots à la bonne manche dans les stats
      final lastEntry = _game.history.last;
      final bonusEntry = HistoryEntry(
        round: _game.currentRound, // Manche actuelle (pas celle d'origine)
        turn: lastEntry.turn, // Même tour pour le graphique d'évolution
        teamId: lastEntry.teamId,
        playerId: lastEntry.playerId,
        wordsGuessed: validatedWords,
        wordsInvalidated: allInvalidatedWords,
        wordsPassed: passedWordsThisTurn,
        timeSpent: currentTimeSpent,
        isBonusContinuation: true, // Marquer comme continuation
        pointsScored: pointsScored,
      );
      // Ajouter l'entrée (pas de remplacement)
      newHistory = [..._game.history, bonusEntry];
      // Ne pas incrémenter le tour car c'est une continuation
      nextTurn = _game.currentTurn;
    } else {
      // Créer une nouvelle entrée normalement
      final historyEntry = HistoryEntry(
        round: _game.currentRound,
        turn: _game.currentTurn,
        teamId: currentTeam.id,
        playerId: currentTeam.playerIds[_game.currentPlayerIndexInTeam],
        wordsGuessed: validatedWords,
        wordsInvalidated: allInvalidatedWords,
        wordsPassed: passedWordsThisTurn,
        timeSpent: currentTimeSpent,
        pointsScored: pointsScored,
      );
      newHistory = [..._game.history, historyEntry];
      nextTurn = _game.currentTurn + 1;
    }

    // Calculer le prochain joueur
    final nextPlayer = _getNextPlayerWithRotation();

    // Fin de la manche?
    if (newRemainingWords.isEmpty) {
      // Préparer la fusion pour le bonus time si pas de mots invalidés
      final shouldPrepareBonusFusion = allInvalidatedWords.isEmpty;

      // Si c'est la dernière manche (manche 3), aller directement aux résultats
      final isLastRound = _game.currentRound >= 3;

      _game = _game.copyWith(
        history: newHistory,
        remainingWords: newRemainingWords,
        currentScreen: isLastRound
            ? AppConstants.screenResults
            : AppConstants.screenTransition,
        turnBonusTime: _game.timeRemaining,
        clearExpiredWord: true,
        fiesta: _fiestaAtRoundEnd(),
        pendingBonusTurnId: shouldPrepareBonusFusion ? _game.currentTurn : null,
        clearPendingBonusTurnId: !shouldPrepareBonusFusion,
      );

      // Dernière manche terminée : la partie est finie, on l'archive.
      if (isLastRound) _archiveGameResult();
    } else {
      // Mélanger les mots restants
      newRemainingWords.shuffle(Random());
      final nextCurrentWord = newRemainingWords[0];

      // Si des mots ont été invalidés, on perd le bonus
      final nextTurnBonusTime =
          allInvalidatedWords.isNotEmpty ? null : _game.turnBonusTime;

      _game = _game.copyWith(
        currentTurn: shouldMergeWithPrevious ? nextTurn : nextTurn,
        currentTurnIndex: nextPlayer['nextTurnIndex'],
        currentTeamIndex: nextPlayer['nextTeamIndex'],
        currentPlayerIndexInTeam: nextPlayer['nextPlayerIndexInTeam'],
        remainingWords: newRemainingWords,
        currentWord: nextCurrentWord,
        wordsGuessedThisTurn: [],
        passedWordsThisTurn: [],
        history: newHistory,
        currentScreen: AppConstants.screenGame,
        turnBonusTime: nextTurnBonusTime,
        clearTurnBonusTime: nextTurnBonusTime == null,
        clearExpiredWord: true,
        clearPendingBonusTurnId: true, // Réinitialiser après usage
        fiesta: _fiestaAfterTurn(),
      );
    }

    notifyListeners();
    _saveGameState();

    // Point de reprise du tracking : la fin d'un tour est le moment où un lot
    // d'événements est complet. On ne le fait PAS à chaque `_saveGameState()`
    // (appelé au moindre changement d'écran) — ce serait doubler l'écriture la
    // plus lourde de l'app pour rien.
    unawaited(_analytics.saveCurrentGame());
  }

  Map<String, int> _getNextPlayerWithRotation() {
    final nextTurnIndex = _game.currentTurnIndex + 1;

    // La longueur du cycle est le NOMBRE D'ÉQUIPES, pas la longueur de la liste
    // stockée : c'est ce qui rend le calcul identique sur une partie sauvegardée
    // à l'ancien format (permutation répétée 1000 fois) et sur le nouveau.
    final cycleLength = _teams.length;

    final nextTeamIndex = teamIndexAtTurn(
      teamPlayOrder: _game.teamPlayOrder,
      cycleLength: cycleLength,
      turnIndex: nextTurnIndex,
    );
    final nextTeam = _teams[nextTeamIndex];

    final nextPlayerIndexInTeam = playerIndexAtTurn(
      playerOrderForTeam: _game.playerOrderByTeam[nextTeam.id] ?? const [],
      cycleLength: cycleLength,
      turnIndex: nextTurnIndex,
    );

    return {
      'nextTurnIndex': nextTurnIndex,
      'nextTeamIndex': nextTeamIndex,
      'nextPlayerIndexInTeam': nextPlayerIndexInTeam,
    };
  }

  void nextRound() {
    // Idempotent par transition : un double tap sur « Manche suivante »
    // rappelait `nextRound` depuis l'écran de jeu de la manche suivante et
    // sautait une manche (M1 → M3). Seul l'écran de transition fait avancer.
    if (_game.currentScreen != AppConstants.screenTransition) return;
    // 1 parmi 3 : la garde est ICI, pas sur le bouton (double tap, reprise).
    if (nextChooserId != null) return;
    final nextRoundNumber = _game.currentRound + 1;

    if (nextRoundNumber > 3) {
      _game = _game.copyWith(
        currentScreen: AppConstants.screenResults,
      );
      _archiveGameResult();
    } else {
      // Réinitialiser le pool de mots
      final shuffledWords = List<String>.from(_game.allWords)
        ..shuffle(Random());
      final nextCurrentWord = shuffledWords[0];

      _game = _game.copyWith(
        currentRound: nextRoundNumber,
        remainingWords: shuffledWords,
        currentWord: nextCurrentWord,
        wordsGuessedThisTurn: [],
        passedWordsThisTurn: [],
        currentScreen: AppConstants.screenGame,
        // Calculé AVANT le changement de manche : le plan de la transition.
        fiesta: _transitionPlan?.apply(_game.fiesta!),
      );
    }

    notifyListeners();
    _saveGameState();
  }

  /// Plan du passage à la manche suivante, recalculé sur l'état de fin de
  /// manche (scores, graine, choix persistés) : montré par la transition
  /// ([nextRoundModifiers], [appBoostPreview], [catchUpPreview]) et appliqué
  /// tel quel par `nextRound`. Nul en Classique et après M3.
  RoundTransitionPlan? get _transitionPlan {
    final fiesta = _game.fiesta;
    if (fiesta == null) return null;
    return planRoundTransition(
      fiesta: fiesta,
      gameId: _game.gameId ?? '',
      finishedRound: _game.currentRound,
      scores: {for (final t in _teams) t.id: t.score},
    );
  }

  /// Rattrapage qui s'appliquera à la manche suivante (vide à égalité ou
  /// rattrapage éteint).
  List<CatchUpEntry> get catchUpPreview => _transitionPlan?.catchUp ?? const [];

  /// Fixés + tirage pour toutes les équipes à la manche suivante.
  List<ModifierInstance> get nextRoundModifiers =>
      _transitionPlan?.draw ?? const [];

  /// Équipe qui ouvre la manche en cours par sa continuation : celle de la
  /// dernière entrée de la manche précédente. Nulle en M1.
  String? get _continuingTeamId => _continuingTeamOf(_game.currentRound);

  /// Équipe qui ouvre la manche [round] par sa continuation (nulle en M1).
  String? _continuingTeamOf(int round) => round <= 1
      ? null
      : _game.history.where((h) => h.round == round - 1).lastOrNull?.teamId;

  int _entriesThisRound(String teamId) => _game.history
      .where((h) => h.round == _game.currentRound && h.teamId == teamId)
      .length;

  /// Le tour en cours est une continuation : l'équipe qui a fini la manche N
  /// poursuit CE tour en N+1 avec le temps reporté. Dérivé de l'historique,
  /// pas de `turnBonusTime` (effacé au départ du chrono) : il tient donc
  /// pendant le tour, sur la vérification, après un kill et un retour arrière.
  bool get isContinuation {
    final teamId = getCurrentTeam()?.id;
    return teamId != null &&
        teamId == _continuingTeamId &&
        _entriesThisRound(teamId) == 0;
  }

  /// Modificateurs qui pèsent sur l'équipe qui joue (badges) : ceux de la
  /// manche LOGIQUE du tour, N pour une continuation ([modifiersForTurn]).
  List<ModifierInstance> get currentTeamModifiers {
    final fiesta = _game.fiesta;
    final teamId = getCurrentTeam()?.id;
    if (fiesta == null || teamId == null) return const [];
    return modifiersForTurn(fiesta.active,
        teamId: teamId,
        logicalRound: _game.currentRound - (isContinuation ? 1 : 0));
  }

  // ========== EFFETS DE TOUR (2-8) ==========

  FiestaTurnState get _turn => _game.fiesta?.turn ?? FiestaTurnState.empty;

  bool _has(String catalogId) =>
      currentTeamModifiers.any((m) => m.catalogId == catalogId);

  /// `no_pass` pèse sur l'équipe qui joue.
  bool get passBlocked => _has('no_pass');

  /// Passes gratuites du tour (`free_pass` ×N), et celles déjà utilisées.
  int get freePasses => chargeAllowance(currentTeamModifiers, 'free_pass');
  int get freePassesUsed => _turn.freePassesUsed;

  /// Il reste une passe gratuite ce tour. Toujours faux en Classique.
  bool get hasFreePass => freePassesUsed < freePasses;

  /// Pénalité EFFECTIVE de la prochaine passe. Classique : la pénalité réglée.
  int get currentPassPenalty => hasFreePass ? 0 : _settings.passPenalty;

  /// 🔴 SEULE garde de la passe, sur la seconde affichée : `passWord` et le
  /// bouton de `turn_screen` la lisent tous deux, sinon le bouton s'affiche
  /// actif et le provider refuse (ou l'inverse).
  bool canPassWith(int displayedSeconds) =>
      !passBlocked && displayedSeconds >= currentPassPenalty;

  /// `reversed` : le mot du tour s'affiche à l'envers (tour seulement).
  bool get isWordReversed => _has('reversed');

  /// Devineurs que les adversaires peuvent bloquer : l'équipe qui joue, sauf
  /// celui qui fait deviner. Vide si `block_guesser` ne la vise pas ou si elle
  /// a 2 joueurs ou moins.
  List<Player> get blockableGuessers {
    final team = getCurrentTeam();
    if (team == null ||
        !_has('block_guesser') ||
        !canBlockGuesser(team.playerIds.length)) {
      return const [];
    }
    final guesserId = getCurrentPlayer()?.id;
    return [
      for (final id in team.playerIds)
        if (id != guesserId) getPlayerById(id),
    ].whereType<Player>().toList();
  }

  /// Devineur bloqué pour ce tour, choisi par les adversaires (annonce seule).
  Player? get blockedGuesser {
    final id = _turn.blockedPlayerId;
    return id == null ? null : getPlayerById(id);
  }

  /// Le sélecteur doit s'ouvrir avant ce tour.
  bool get needsBlockedGuesser =>
      blockableGuessers.isNotEmpty && blockedGuesser == null;

  void setBlockedGuesser(String playerId) {
    final fiesta = _game.fiesta;
    if (fiesta == null || !blockableGuessers.any((p) => p.id == playerId)) {
      return;
    }
    _game = _game.copyWith(
      fiesta: fiesta.copyWith(
          turn: fiesta.turn.copyWith(blockedPlayerId: playerId)),
    );
    notifyListeners();
    _saveGameState();
  }

  // ========== BONUS À CHARGE : ×2 (2-9), DEUX MOTS (2-11) ==========
  // Une table (`kChargeBonusKeys`), une implémentation : chaque getter public
  // n'est qu'un id de catalogue.

  /// Modificateurs EN JEU pendant le tour (badges du tour, tags analytics) :
  /// une charge non activée n'en est pas un (activée : badge et tag à part).
  List<ModifierInstance> get turnModifiers => currentTeamModifiers
      .where((m) => !kChargeBonusKeys.containsKey(m.catalogId))
      .toList();

  ChargeState? _charge(String id) => _turn.charges[id];

  /// Charges restantes de l'équipe qui joue pour la manche en cours (celles
  /// des manches finies sont perdues). Aucune sur une continuation : c'est
  /// le même tour que la fin de N, on n'y allume rien, et les charges de N+1
  /// commencent au premier vrai tour.
  int _chargesLeft(String id) {
    if (isContinuation) return 0;
    final teamId = getCurrentTeam()?.id;
    final used = (_game.fiesta?.chargesUsed ?? const <ChargeUse>[])
        .where((u) =>
            u.catalogId == id &&
            u.teamId == teamId &&
            u.round == _game.currentRound)
        .length;
    return chargeAllowance(currentTeamModifiers, id) - used;
  }

  /// Q8 : allumer est refusé si l'équipe a déjà 2 modificateurs en jeu, l'autre
  /// bonus allumé compris.
  bool _capped(String id) =>
      turnModifiers.length +
          kChargeBonusKeys.keys
              .where((other) => other != id && _charge(other) != null)
              .length >=
      2;

  /// Interrupteur d'un bonus à charge, avant le départ : seul `armed` est
  /// écrit ; la charge se dépense dans `startTurnTimer`.
  void _setCharge(String id, bool on) {
    final fiesta = _game.fiesta;
    if (fiesta == null ||
        _charge(id) == ChargeState.spent ||
        (on && (_chargesLeft(id) <= 0 || _capped(id)))) {
      return;
    }
    _game = _game.copyWith(
      fiesta: fiesta.copyWith(
          turn: fiesta.turn.withCharge(id, on ? ChargeState.armed : null)),
    );
    notifyListeners();
    _saveGameState();
  }

  /// Interrupteur de l'avant-tour allumé (ou charge déjà dépensée).
  bool get isDoublePointsArmed => _charge('double_points') != null;

  /// Les points de CE tour comptent ×2 : charge dépensée au départ. Vaut aussi
  /// pour la continuation de fin de manche, qui est le même tour.
  bool get isDoublePointsOn => _charge('double_points') == ChargeState.spent;
  int get doublePointsLeft => _chargesLeft('double_points');
  bool get doublePointsCapped => _capped('double_points');
  void setDoublePoints(bool on) => _setCharge('double_points', on);

  /// Deux mots à l'écran pendant CE tour (continuation comprise).
  bool get isTwoWordsArmed => _charge('two_words') != null;
  bool get isTwoWordsOn => _charge('two_words') == ChargeState.spent;
  int get twoWordsLeft => _chargesLeft('two_words');
  bool get twoWordsCapped => _capped('two_words');
  void setTwoWords(bool on) => _setCharge('two_words', on);

  /// Carte B (la carte A est `game.currentWord`). Nulle = une seule carte.
  String? get secondWord => _turn.secondWord;

  /// Carte B encore à l'écran quand le chrono est tombé, à vérifier.
  String? get secondExpiredWord => _turn.secondExpiredWord;

  /// Cartes après le traitement (trouvé ou passé) de [target], l'une des deux
  /// cartes : elle seule est remplacée, par un mot ≠ l'autre carte
  /// ([drawOtherCard]). Plus aucun autre mot : l'autre carte reste seule, en
  /// tête. [pool] est déjà privé de [target].
  ({String? first, String? second, String? drawn, List<String> pool})
      _cardsAfter(String target,
          {required List<String> pool, required List<String> passed}) {
    final a = _game.currentWord!;
    final b = secondWord!;
    final isA = target == a;
    final other = isA ? b : a;
    final next = drawOtherCard(pool: pool, passed: passed, other: other);
    final drawn = next.word;
    if (drawn == null) {
      return (first: other, second: null, drawn: null, pool: next.pool);
    }
    return isA
        ? (first: drawn, second: b, drawn: drawn, pool: next.pool)
        : (first: a, second: drawn, drawn: drawn, pool: next.pool);
  }

  /// [fiesta] avec la carte B [word] (nulle = plus de carte B).
  FiestaState _withSecondWord(FiestaState fiesta, String? word) =>
      fiesta.copyWith(
          turn: word == null
              ? fiesta.turn.copyWith(clearSecondWord: true)
              : fiesta.turn.copyWith(secondWord: word));

  /// Fiesta à la VRAIE fin d'un tour : état du tour vidé, instances de portée
  /// tour qui ont pesé sur ce tour consommées. 🔴 Une fin de manche n'en est
  /// pas une : la continuation en N+1 est le même tour. À la fin d'une
  /// continuation, les instances de N, qui ne servaient qu'à elle, partent.
  /// Nul en Classique.
  FiestaState? _fiestaAfterTurn() {
    final fiesta = _game.fiesta;
    if (fiesta == null || _teams.isEmpty) return null;
    final applied = currentTeamModifiers;
    final continuation = isContinuation;
    return fiesta.copyWith(
      turn: FiestaTurnState.empty,
      active: fiesta.active
          .where((m) =>
              !(m.scope == ModifierScope.turn && applied.contains(m)) &&
              !(continuation && m.round < _game.currentRound))
          .toList(),
    );
  }

  /// Fiesta à une fin de manche. D'ordinaire, la même équipe poursuit CE tour
  /// en N+1 (continuation) : l'état du tour vit jusqu'à sa vraie fin
  /// ([FiestaTurnState.afterRoundEnd]). Mais si ce tour était DÉJÀ une
  /// continuation (elle a vidé le pool de N+1 à elle seule), son tour logique
  /// N se termine ici, comme à une vraie fin de tour : la continuation
  /// suivante ne porte alors que le contexte de N+1, jamais celui de N.
  FiestaState? _fiestaAtRoundEnd() {
    final fiesta = _game.fiesta;
    if (fiesta == null) return null;
    if (isContinuation) return _fiestaAfterTurn();
    return fiesta.copyWith(turn: fiesta.turn.afterRoundEnd());
  }

  /// Malus à révéler en plein écran avant le tour : ceux de l'équipe qui joue,
  /// à son premier tour de la manche LOGIQUE du tour (celle de ses effets).
  /// Une continuation ordinaire ne révèle rien (l'équipe a déjà joué en N) ;
  /// une continuation en chaîne révèle les malus de N+1, qu'elle subit pour
  /// la première fois, sauf les malus de temps : une continuation joue
  /// exactement son temps reporté, un « −10 s » annoncé n'y serait pas
  /// appliqué. L'entrée de la continuation ne compte jamais comme un tour de
  /// sa manche. Dérivé de l'historique : rien à persister.
  List<ModifierInstance> get malusToReveal {
    final teamId = getCurrentTeam()?.id;
    if (_game.fiesta == null || teamId == null) return const [];
    final round = _game.currentRound - (isContinuation ? 1 : 0);
    final realTurns = _game.history
            .where((h) => h.round == round && h.teamId == teamId)
            .length -
        (teamId == _continuingTeamOf(round) ? 1 : 0);
    if (realTurns > 0) return const [];
    final continuation = isContinuation;
    return currentTeamModifiers
        .where((m) =>
            m.nature == ModifierNature.malus &&
            !(continuation && kTimeModifierIds.contains(m.catalogId)))
        .toList();
  }

  // ========== 1 PARMI 3 / COUP DE POUCE (2-10) ==========
  // Tout est RECALCULÉ depuis les scores, le tirage de N+1 et la graine
  // `(gameId, manche, équipe)` : retour arrière et app tuée retrouvent les
  // mêmes offres. Seuls les choix faits sont persistés (`offerChoices`).

  /// Classement de fin de manche (scores actuels, dans l'ordre des équipes).
  Standings get standings => Standings({for (final t in _teams) t.id: t.score});

  /// Choix déjà faits sur la transition en cours, par équipe qui a choisi.
  Map<String, ModifierInstance> get _pendingChoices => {
        for (final c in _game.fiesta?.offerChoices ?? const <OfferChoice>[])
          if (c.modifier.round == _game.currentRound + 1)
            c.chooserId: c.modifier,
      };

  bool get _isPickThreeOn {
    final fiesta = _game.fiesta;
    return fiesta != null &&
        _game.currentScreen == AppConstants.screenTransition &&
        isPickThreeOn(fiesta.rules, _game.currentRound);
  }

  /// Offres de [teamId] sur la transition, compte tenu du tirage de N+1 et
  /// des choix déjà faits. Vide hors 1 parmi 3.
  List<ModifierInstance> offersFor(String teamId) {
    if (!_isPickThreeOn) return const [];
    return pickThreeOffers(
      rules: _game.fiesta!.rules,
      gameId: _game.gameId ?? '',
      round: _game.currentRound,
      standings: standings,
      teamId: teamId,
      roundDraw: nextRoundModifiers,
      choices: _pendingChoices,
      blockImmuneTeamIds: {
        for (final t in _teams)
          if (!canBlockGuesser(t.playerIds.length)) t.id,
      },
    );
  }

  /// Prochaine équipe de la file : la première de l'ordre de choix qui n'a
  /// pas encore choisi et qui a des offres. `null` = file vide (ou pas de
  /// 1 parmi 3) : « Manche suivante » est permis.
  String? get nextChooserId {
    if (!_isPickThreeOn) return null;
    final made = _pendingChoices;
    for (final id in standings.choosingOrder) {
      if (!made.containsKey(id) && offersFor(id).isNotEmpty) return id;
    }
    return null;
  }

  /// La carte « 1 parmi 3 » a lieu sur cette transition (au moins un choix à
  /// faire ou déjà fait).
  bool get hasPickThree =>
      nextChooserId != null || (_isPickThreeOn && _pendingChoices.isNotEmpty);

  /// [teamId] choisit son offre n° [index]. Refusé si ce n'est pas son tour.
  void chooseOffer(String teamId, int index) {
    if (teamId != nextChooserId) return;
    final offers = offersFor(teamId);
    if (index < 0 || index >= offers.length) return;
    final fiesta = _game.fiesta!;
    _game = _game.copyWith(
      fiesta: fiesta.copyWith(offerChoices: [
        ...fiesta.offerChoices,
        OfferChoice(chooserId: teamId, modifier: offers[index]),
      ]),
    );
    notifyListeners();
    _saveGameState();
  }

  /// Coup de pouce de l'app (Auto) pour la manche suivante. Vide hors Auto +
  /// auto-calibrage, après M3 ou à égalité.
  List<ModifierInstance> get appBoostPreview =>
      _transitionPlan?.gifts ?? const [];

  /// Équipe qui désigne le devineur bloqué de l'équipe qui joue : celle qui a
  /// choisi « Bloquer un devineur » contre elle. `null` = les adversaires.
  Team? get blockingTeam {
    final block = currentTeamModifiers
        .where((m) => m.catalogId == 'block_guesser')
        .firstOrNull;
    if (block == null) return null;
    for (final c in _game.fiesta?.offerChoices ?? const <OfferChoice>[]) {
      if (c.modifier.catalogId == 'block_guesser' &&
          c.modifier.teamId == block.teamId &&
          c.modifier.round == block.round) {
        return getTeamById(c.chooserId);
      }
    }
    return null;
  }

  /// Récap « Modificateurs de la partie », en faits (archivés). Vide en
  /// Classique.
  List<ModifierRecapItem> get _modifierRecapItems {
    final fiesta = _game.fiesta;
    if (fiesta == null) return const [];
    return buildModifierRecap(
      rules: fiesta.rules,
      chargesUsed: fiesta.chargesUsed,
      offerChoices: fiesta.offerChoices,
      gameId: _game.gameId ?? '',
      teams: _teams,
      roundsPlayed: _game.currentRound,
    );
  }

  /// Le même récap, en lignes affichées (écran Résultats).
  List<ModifierRecapLine> get modifierRecap => formatModifierRecap(
        _modifierRecapItems,
        teamNames: {for (final t in _teams) t.id: t.name},
      );

  /// Archive la partie terminée pour l'écran d'historique.
  ///
  /// On enregistre le résultat **tel qu'il a été montré aux joueurs**, pas une
  /// reconstruction depuis les events : la validation manuelle de fin de tour
  /// invalide des mots, les mots passés sont recyclés, et ces règles évolueront
  /// (mode Fiesta). Un score recalculé après coup finirait par diverger de celui
  /// affiché — et c'est le score affiché qui fait foi pour les joueurs.
  ///
  /// Volontairement fire-and-forget et enveloppé : l'archivage est une commodité,
  /// il ne doit jamais empêcher l'écran de résultats de s'afficher.
  void _archiveGameResult() {
    final gameId = _game.gameId;
    if (gameId == null || _teams.isEmpty) return;

    final result = GameResult(
      gameId: gameId,
      playedAt: DateTime.now(),
      teams: _teams
          .map((team) => TeamResult(
                id: team.id,
                name: team.name,
                score: team.score,
                scoreByRound: List<int>.from(team.scoreByRound),
                playerNames: team.playerIds
                    .map((id) => getPlayerById(id)?.name)
                    .whereType<String>()
                    .toList(),
              ))
          .toList(),
      totalWords: _game.allWords.length,
      turnDuration: _settings.turnDuration,
      roundsPlayed: _game.currentRound,
      mode: _game.fiesta == null ? null : fiestaModeId(_game.fiesta!.rules),
      modifierRecap: _game.fiesta == null ? null : _modifierRecapItems,
      setup: GameSetupSnapshot(
        settings: _settings.copyWith(),
        fiesta: _game.fiesta?.rules,
      ),
    );

    unawaited(_history.record(result));
  }

  // ========== ACTIONS - NAVIGATION ==========

  void goToScreen(String screenName) {
    // En Aléatoire, les mots tirés ne se montrent jamais (badge « mots prêts »).
    if (screenName == AppConstants.screenWords &&
        _settings.wordChoice == AppConstants.wordChoiceRandom) {
      return;
    }
    _game = _game.copyWith(currentScreen: screenName);
    notifyListeners();
    // Sauvegarder seulement si une partie est en cours
    if (_game.isGameSuspended || _game.allWords.isNotEmpty) {
      _saveGameState();
    }
  }

  Future<void> suspendGame() async {
    // Sauvegarder les analytics en cours (au cas où l'app serait tuée)
    await _analytics.saveCurrentGame();

    final now = DateTime.now().millisecondsSinceEpoch;

    // 🔴 On GÈLE l'horloge au lieu de relire une deadline restée vivante.
    // Avant : l'écran mettait `_isPaused = true` sans toucher à la deadline,
    // puis cette méthode recalculait le reste depuis cette deadline périmée —
    // donc tout le temps passé dans le dialogue était décompté, et au-delà du
    // temps restant le `clamp` donnait 0, ce qui terminait le tour au retour.
    // La valeur correcte était pourtant déjà capturée par le widget, et ignorée.
    // `pauseAt` est idempotent : si l'écran a déjà gelé, on garde son reste.
    final frozen = turnClock.pauseAt(now);

    // Suspendre hors d'un tour (écran équipes, réglages…) : il n'y a pas
    // d'horloge à geler, mais l'ancien code posait quand même un reste égal au
    // temps affiché. On conserve ce comportement au lieu de le changer au
    // passage — ce n'est pas l'objet de ce correctif.
    final clock = frozen.isStopped
        ? TurnClock.frozen(_game.timeRemaining * 1000)
        : frozen;

    _game = _withClock(_game, clock, nowMs: now).copyWith(
      isGameSuspended: true,
      suspendedScreen: _game.currentScreen,
      currentScreen: AppConstants.screenHome,
    );

    notifyListeners();
    _saveGameState();
  }

  void resumeGame() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 🔴 Passer par `_withClock`, et non écrire les champs à la main : c'est CE
    // contournement qui rendait du temps au joueur. `suspendGame` écrivait un
    // reste arrondi à la seconde SUPÉRIEURE, `resumeGame` le relisait comme
    // exact — donc chaque aller-retour par l'accueil allongeait le tour de
    // jusqu'à 999 ms, autant de fois qu'on le répétait.
    _game = _withClock(_game, turnClock.resumeAt(now), nowMs: now).copyWith(
      currentScreen: _game.suspendedScreen ?? AppConstants.screenGame,
      isGameSuspended: false,
      clearSuspendedScreen: true,
    );

    notifyListeners();
    _saveGameState();
  }

  // ========== ACTIONS - RESET ==========

  // Efface les joueurs et équipes (utilisé quand on revient aux paramètres)
  void clearPlayersData() {
    _players = [];
    _teams = [];
    notifyListeners();
    _saveGameSession();
  }

  // Fin de partie normale → efface gameState, garde session pour "Rejouer"
  Future<void> endGameAndGoHome() async {
    // Terminer le tracking analytics et sauvegarder
    await _analytics.endGame();

    await _storage.clearGameState();
    // `_pendingFiesta` n'est PAS effacé : le « Rejouer » de l'accueil le relit.
    _game = GameState.initial();
    notifyListeners();
  }

  // Nouvelle partie complète → efface session ET state, garde settings
  Future<void> startNewGame() async {
    // Terminer et sauvegarder les analytics si une partie était en cours
    if (_analytics.isTracking) {
      await _analytics.endGame();
    }

    await _storage.clearGameSession();
    await _storage.clearGameState();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    _pendingFiesta = null;
    notifyListeners();
  }

  // Rejouer avec mêmes joueurs → efface mots, reset scores, va aux paramètres,
  // avec la config Fiesta de la partie finie en attente (Q12).
  Future<void> restartWithSamePlayers() async {
    // 🔴 Lire AVANT `GameState.initial()` ci-dessous, qui efface `fiesta`.
    // Sans partie jouée (Rejouer de l'accueil, après `endGameAndGoHome`), la
    // config déjà en mémoire fait foi.
    if (_game.allWords.isNotEmpty) _pendingFiesta = _game.fiesta?.rules;
    // Auto = symétrique + auto-calibrage toujours allumés (plus d'écran pour
    // les couper) : une partie d'avant la mise à jour qui en avait coupé un
    // ne le transmet pas à la suivante.
    if (_pendingFiesta?.mode == FiestaMode.auto) {
      _pendingFiesta = FiestaRules(mode: FiestaMode.auto);
    }

    // Terminer et sauvegarder les analytics si une partie était en cours
    if (_analytics.isTracking) {
      await _analytics.endGame();
    }

    await _storage.clearGameState();

    // Effacer les mots de tous les joueurs
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(words: []);
    }

    // Reset scores des équipes
    for (int i = 0; i < _teams.length; i++) {
      _teams[i] = _teams[i].copyWith(
        score: 0,
        scoreByRound: [0, 0, 0],
      );
    }

    _game = GameState.initial()
        .copyWith(currentScreen: AppConstants.screenSettings);
    await _saveGameSession();
    notifyListeners();
  }

  /// « Rejouer » depuis l'historique : recrée joueurs et équipes de [result],
  /// reprend ses réglages (et ses règles Fiesta), puis atterrit comme le
  /// « Rejouer » de fin de partie. Les mots ne sont jamais rejoués.
  ///
  /// Archive antérieure (sans `setup`) : seuls `totalWords` et `turnDuration`
  /// viennent de l'archive, le reste des réglages courants, en Classique.
  /// 🔴 Remplace une éventuelle partie suspendue : l'écran confirme avant.
  Future<void> replayFromHistory(GameResult result) async {
    final setup = result.setup;
    final players = <Player>[];
    final teams = <Team>[];
    for (var i = 0; i < result.teams.length; i++) {
      final archived = result.teams[i];
      final teamPlayers = archived.playerNames.map(Player.create).toList();
      players.addAll(teamPlayers);
      final team = Team.create(i);
      teams.add(team.copyWith(
        name: archived.name.isEmpty ? team.name : archived.name,
        playerIds: teamPlayers.map((p) => p.id).toList(),
      ));
    }

    // Archive sans snapshot : n'en reprendre que les valeurs que les
    // curseurs d'« Avancés » acceptent (`Slider` lève hors bornes).
    int? inRange(int v, int min, int max) => v >= min && v <= max ? v : null;
    final base = setup?.settings ??
        _settings.copyWith(
          totalWords: inRange(result.totalWords, AppConstants.minTotalWords,
              AppConstants.maxTotalWords),
          turnDuration: inRange(result.turnDuration,
              AppConstants.minTurnDuration, AppConstants.maxTurnDuration),
        );
    // Les effectifs suivent les joueurs recréés, pas un réglage archivé qui
    // pourrait les contredire.
    // Catégories disparues du catalogue depuis l'archive : retirées ; s'il
    // n'en reste aucune, les catégories courantes.
    final known = (await getCategoryListAsync()).map((c) => c.id).toSet();
    final categories = base.selectedCategories.where(known.contains).toList();
    _settings = base.copyWith(
      numberOfTeams: teams.length,
      numberOfPlayers: players.length,
      selectedCategories: categories.isEmpty
          ? List.of(_settings.selectedCategories)
          : categories,
    );
    _players = players;
    _teams = teams;
    _pendingFiesta = setup?.fiesta;
    // Sans ce reset, `restartWithSamePlayers` relirait la Fiesta de la partie
    // suspendue par-dessus celle de l'archive.
    _game = GameState.initial();
    await _saveSettings();
    await restartWithSamePlayers();
  }

  // Réinitialise TOUT : paramètres, joueurs, mots, équipes, état de jeu
  Future<void> clearLocalStorage() async {
    await _storage.clearGameState();
    await _storage.clearGameSession();
    _settings = GameSettings.initial();
    await _saveSettings();
    _players = [];
    _teams = [];
    _game = GameState.initial();
    _pendingFiesta = null;
    notifyListeners();
  }

  // DEPRECATED: Utiliser startNewGame() à la place
  void resetGame() {
    _players = [];
    _teams = [];
    _game = GameState.initial();
    _pendingFiesta = null;
    notifyListeners();
    _storage.clearGameSession();
    _storage.clearGameState();
  }

  // ========== HELPERS ==========

  Player? getPlayerById(String playerId) {
    try {
      return _players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  Team? getTeamById(String teamId) {
    try {
      return _teams.firstWhere((t) => t.id == teamId);
    } catch (e) {
      return null;
    }
  }

  Player? getCurrentPlayer() {
    if (_teams.isEmpty || _game.currentTeamIndex >= _teams.length) return null;
    final currentTeam = _teams[_game.currentTeamIndex];
    if (currentTeam.playerIds.isEmpty ||
        _game.currentPlayerIndexInTeam >= currentTeam.playerIds.length) {
      return null;
    }
    final playerId = currentTeam.playerIds[_game.currentPlayerIndexInTeam];
    return getPlayerById(playerId);
  }

  Team? getCurrentTeam() {
    if (_teams.isEmpty || _game.currentTeamIndex >= _teams.length) return null;
    return _teams[_game.currentTeamIndex];
  }

  List<Team> getTeamsSortedByScore() {
    final sortedTeams = List<Team>.from(_teams);
    sortedTeams.sort((a, b) {
      // D'abord par score décroissant
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;

      // En cas d'égalité, celui qui a commencé plus tard gagne
      final indexA = _teams.indexWhere((t) => t.id == a.id);
      final indexB = _teams.indexWhere((t) => t.id == b.id);
      final orderA = _game.teamPlayOrder.indexOf(indexA);
      final orderB = _game.teamPlayOrder.indexOf(indexB);

      // Plus grand = a commencé plus tard = meilleur classement
      return orderB.compareTo(orderA);
    });
    return sortedTeams;
  }

  bool get hasPlayersWithNames => _players.any((p) => p.name.trim().isNotEmpty);

  bool get allTeamsHaveMinPlayers =>
      _teams.every((t) => t.playerIds.length >= 2);

  int get totalWordsEntered =>
      _players.fold(0, (sum, p) => sum + p.words.length);

  int get expectedTotalWords => _settings.totalWords;

  /// Nombre effectif de mots restants (incluant les passés recyclables)
  int get effectiveRemainingWordsCount {
    final remainingSet = _game.remainingWords.toSet();

    // Mots passés qui ne sont PAS déjà dans remainingWords
    final passedNotInRemaining = _game.passedWordsThisTurn
        .where((w) => !remainingSet.contains(w))
        .length;

    // Total = remainingWords + passés non recyclés - mot(s) à l'écran
    // (deux avec « Deux mots à la fois »)
    final onScreen = secondWord != null ? 2 : 1;
    return _game.remainingWords.length + passedNotInRemaining - onScreen;
  }

  /// Retourne la distribution des mots par joueur
  /// Les premiers joueurs ont 1 mot de plus si la répartition est inégale
  Map<String, int> getWordsDistribution() {
    final playerCount = _players.length;
    if (playerCount == 0) return {};

    final baseWords = _settings.totalWords ~/ playerCount;
    final extraWords = _settings.totalWords % playerCount;

    final distribution = <String, int>{};
    for (int i = 0; i < _players.length; i++) {
      final wordsForPlayer = baseWords + (i < extraWords ? 1 : 0);
      distribution[_players[i].id] = wordsForPlayer;
    }
    return distribution;
  }

  /// Retourne le nombre de mots pour un joueur spécifique
  int getWordsCountForPlayer(String playerId) {
    final distribution = getWordsDistribution();
    return distribution[playerId] ?? 0;
  }

  // Vérifie si une session existe (joueurs d'une partie précédente)
  // Utilisé pour proposer "Rejouer" sur l'écran d'accueil
  bool get hasGameSession =>
      _players.isNotEmpty && _teams.isNotEmpty && !_game.isGameSuspended;

  // ========== NAVIGATION RETOUR ==========

  // Vérifie si c'est le tout premier tour de la partie
  bool get isFirstTurnOfGame =>
      _game.history.isEmpty && _game.currentRound == 1;

  // Vérifie si on peut revenir à l'écran de vérification
  bool get canGoBackToVerification => _game.preValidationSnapshot != null;

  // Sauvegarde l'état avant validation (appelé dans verification_screen)
  // validatedWords = les mots que l'utilisateur a choisi de valider
  //
  // 🔴 Le snapshot réutilise `GameState.toJson()`, la sérialisation CANONIQUE.
  // Avant, c'était une SECONDE sérialisation écrite à la main : 15 champs
  // recopiés, à re-synchroniser à chaque ajout de champ — et relus avec des
  // casts durs (`as int`, `as List`) qui levaient sur la moindre absence.
  // Un champ ajouté à GameState et oublié ici se traduisait par une restauration
  // silencieusement incomplète. C'est exactement le piège que le mode Fiesta
  // aurait déclenché, lui qui ajoutera des champs d'état par construction.
  void savePreValidationState(List<String> validatedWords) {
    // Double tap : ne pas écraser le snapshot par l'état déjà validé.
    if (_game.currentScreen != AppConstants.screenVerification) return;
    _game = _game.copyWith(
      preValidationSnapshot: {
        // On retire le snapshot de lui-même : sans ça, chaque sauvegarde
        // imbriquerait la précédente et le blob grossirait sans fin.
        'game': _game.copyWith(clearPreValidationSnapshot: true).toJson(),
        'teamScores': _teams
            .map((t) => {
                  'id': t.id,
                  'score': t.score,
                  'scoreByRound': List<int>.from(t.scoreByRound),
                })
            .toList(),
        'validatedWords': List<String>.from(validatedWords),
      },
    );
    notifyListeners();
    _saveGameState();
  }

  // Restaure l'état avant validation (appelé quand on clique sur retour)
  void restorePreValidationState() {
    final snapshot = _game.preValidationSnapshot;
    if (snapshot == null) return;

    final gameJson = snapshot['game'];
    // Un snapshot écrit par l'ancienne version (format à plat) ou corrompu :
    // on renonce au retour arrière plutôt que de crasher. L'utilisateur perd la
    // possibilité de revenir sur CE tour, rien d'autre.
    if (gameJson is! Map<String, dynamic>) return;

    // Restaurer les scores des équipes
    final teamScores = snapshot['teamScores'];
    if (teamScores is List) {
      for (final ts in teamScores) {
        if (ts is! Map) continue;
        final idx = _teams.indexWhere((t) => t.id == ts['id']);
        if (idx != -1) {
          _teams[idx] = _teams[idx].copyWith(
            score: ts['score'] as int? ?? _teams[idx].score,
            scoreByRound: (ts['scoreByRound'] as List?)?.cast<int>() ??
                _teams[idx].scoreByRound,
          );
        }
      }
    }

    final validatedWords = snapshot['validatedWords'];

    _game = GameState.fromJson(gameJson).copyWith(
      currentScreen: AppConstants.screenVerification,
      clearPreValidationSnapshot: true,
      restoredValidatedWords:
          validatedWords is List ? validatedWords.cast<String>() : null,
    );

    notifyListeners();
    _saveGameState();
  }

  // Retour à l'écran de composition des équipes (premier tour uniquement)
  void goBackToTeams() {
    _game = _game.copyWith(
      currentScreen: AppConstants.screenTeams,
      clearPreValidationSnapshot: true,
    );
    notifyListeners();
  }

  // Efface les mots validés restaurés après utilisation par verification_screen
  void clearRestoredValidatedWords() {
    if (_game.restoredValidatedWords != null) {
      _game = _game.copyWith(clearRestoredValidatedWords: true);
      notifyListeners();
    }
  }
}
