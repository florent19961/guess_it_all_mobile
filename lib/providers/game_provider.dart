import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/fiesta/cartridge_gifts.dart';
import '../models/fiesta/fiesta_ensemble.dart';
import '../models/fiesta/fiesta_rules.dart';
import '../models/fiesta/fiesta_state.dart';
import '../models/fiesta/giver_block.dart';
import '../models/fiesta/modifier_catalog.dart';
import '../models/fiesta/modifier_instance.dart';
import '../models/fiesta/modifier_recap.dart';
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
import '../services/fiesta_ensemble_service.dart';
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

  /// Choix Fiesta fait sur les Paramètres et l'ensemble choisi juste après, en
  /// attente de `startGame`. Nul = Classique. Les règles restent en mémoire ; le
  /// CHOIX survit à l'app tuée et à « Nouvelle partie »
  /// (`GameSettings.fiestaEnabled` et `replayFiesta`, `lastUsedId` des ensembles :
  /// [_rememberedFiesta]).
  FiestaRules? _pendingFiesta;
  FiestaRules? get pendingFiesta => _pendingFiesta;
  String? get currentEditingPlayerId => _currentEditingPlayerId;

  void setPendingFiesta(FiestaRules? rules) {
    _pendingFiesta = rules;
    _rememberFiestaChoice();
    notifyListeners();
  }

  /// Écrit le choix d'attente dans les réglages. [replay] : un « Rejouer » garde
  /// les règles gelées de son ensemble ; tout choix explicite les efface.
  void _rememberFiestaChoice({bool replay = false}) {
    final keep = replay && _pendingFiesta?.ensembleName != null;
    _settings = _settings.copyWith(
      fiestaEnabled: _pendingFiesta != null,
      replayFiesta: keep ? _pendingFiesta : null,
      clearReplayFiesta: !keep,
    );
    _saveSettings();
  }

  /// Le dernier choix relu du stockage : Classique (nul), une partie rejouée
  /// pas encore lancée, ou le dernier ensemble utilisé (supprimé ou illisible :
  /// Fiesta classique).
  /// `FiestaEnsembleService.load` ne lève jamais.
  Future<FiestaRules?> _rememberedFiesta() async {
    if (!_settings.fiestaEnabled) return null;
    if (_settings.replayFiesta case final rules?) return rules;
    final store = await FiestaEnsembleService().load();
    final ensembles = [...kProvidedEnsembles, ...store.ensembles];
    return (ensembles.where((e) => e.id == store.lastUsedId).firstOrNull ??
            classicEnsemble)
        .rules;
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
      _pendingFiesta = await _rememberedFiesta();

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
        final rawGame = savedState['game'] ?? {};
        _game = GameState.fromJson(rawGame);
        // Partie Fiesta d'une forme illisible (ex. Fiesta v1, avant le
        // modèle des ensembles v2) : on ne la reprend pas en Classique, on
        // l'abandonne proprement (retour à l'accueil, joueurs et équipes
        // gardés). Jamais de crash.
        if (rawGame is Map && GameState.hasUnreadableFiesta(rawGame)) {
          debugPrint('[GameProvider] Partie Fiesta illisible, abandonnée');
          _game = GameState();
          await _storage.clearGameState();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          return;
        }
        // Partie Fiesta reprise après un kill : remettre sa config gelée en
        // attente, sinon « Retour aux équipes » + « Lancer » la relancerait en
        // Classique. Invariant : en partie, `pendingFiesta` = `fiesta?.rules`.
        // Une partie suspendue garde sa config, sans toucher au dernier choix.
        if (_game.allWords.isNotEmpty) _pendingFiesta = _game.fiesta?.rules;

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

    final rules = fiesta;
    final firstRules = rules == null
        ? const <ModifierInstance>[]
        : roundModifiers(rules, gameId: gameId, round: 1);

    _game = _game.copyWith(
      gameId: gameId,
      scoreRevealSeen: false,
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
              active: firstRules,
              earned: roundGifts(
                rules: rules,
                gameId: gameId,
                finishedRound: 0,
                scores: {for (final t in _teams) t.id: 0},
                totalWords: shuffledWords.length,
                roundRules: firstRules,
                blockableTeamIds: _blockableTeamIds,
              ),
            ),
      clearFiesta: rules == null,
    );

    // La partie rejouée est lancée : elle ne prime plus sur le dernier choix.
    if (_settings.replayFiesta != null) {
      _settings = _settings.copyWith(clearReplayFiesta: true);
      _saveSettings();
    }

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
      gameMode: _game.fiesta == null ? null : kFiestaModeId,
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
  /// part à 48. Continuation (`turnBonusTime` posé) = ses secondes, + 10 s si
  /// le bonus y est allumé. En Classique : `turnBonusTime ?? turnDuration`,
  /// comme avant.
  TurnTime get turnTime {
    final plus10s = _charge('plus_10s');
    return composeTurnSeconds(
      baseSeconds: _settings.turnDuration,
      carriedSeconds: _game.turnBonusTime,
      // Allumé ou dépensé : l'aperçu et le chrono comptent la même chose. Sur
      // un report, dépensé = déjà compté dans ces secondes.
      plus10sCount: (_game.turnBonusTime == null
              ? plus10s != null
              : plus10s == ChargeState.armed)
          ? 1
          : 0,
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
    // 🔴 Le piège d'« Interdit de faire deviner » : le décompte s'est déroulé
    // normalement, mais le chrono ne part pas et rien n'est dépensé. Rien n'est
    // consommé avant `confirmGiverBlock` : une app tuée remontre la phrase.
    if (_pendingGiverBlock != null) {
      _game = _game.copyWith(currentScreen: AppConstants.screenGiverBlocked);
      notifyListeners();
      _saveGameState();
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    // À lire AVANT d'effacer `turnBonusTime` : c'est lui qui dit si ce tour est
    // une continuation, et avant de dépenser les charges.
    final durationSeconds = turnTime.total;
    final durationMs = durationSeconds * 1000;
    var fiesta = _game.fiesta;
    // Le lien « Reprendre les choix de… » ne vit que sur cet avant-tour.
    if (fiesta != null && fiesta.turn.replaced != null) {
      fiesta = fiesta.copyWith(turn: fiesta.turn.copyWith(clearReplaced: true));
    }
    // Lu seulement en Fiesta : en Classique, rien n'exige une équipe ici.
    final teamId = fiesta == null ? '' : _teams[_game.currentTeamIndex].id;
    // Bonus à charge (×2, deux mots, passe gratuite, +10 s) : la charge se dépense ICI, pas à
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
          ChargeUse(
              catalogId: id,
              teamId: teamId,
              round: _game.currentRound,
              turn: _game.currentTurn),
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
                for (final id in kChargeBonusKeys.keys)
                  if (_charge(id) == ChargeState.spent) id,
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
    // Idempotent : le chrono et la confirmation « Terminer » peuvent se croiser.
    // Un second appel ajouterait un événement `expired` pour le même mot.
    if (_game.currentScreen != AppConstants.screenTurn) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Passe par l'horloge : si le tour était GELÉ (app en arrière-plan, dialogue
    // ouvert), c'est le reste gelé qui compte — pas une deadline périmée.
    final timeRemaining = turnClock.displayedSecondsAt(now);

    // Si la manche n'est pas finie et qu'il y avait un mot en cours, le sauvegarder comme "expiré"
    final isRoundFinished = _game.remainingWords.isEmpty;
    final expiredWord = isRoundFinished ? null : _game.currentWord;

    // Deux mots : la carte B part aussi à la vérification, sous sa propre clé.
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

      _game = _game.copyWith(
        history: newHistory,
        remainingWords: newRemainingWords,
        // Après M3 aussi : écran fixe, dernière chance de contester le dernier
        // tour. La partie s'archive à « Voir les résultats » (`nextRound`).
        currentScreen: AppConstants.screenTransition,
        turnBonusTime: _game.timeRemaining,
        clearExpiredWord: true,
        fiesta: _fiestaAtRoundEnd(),
        pendingBonusTurnId: shouldPrepareBonusFusion ? _game.currentTurn : null,
        clearPendingBonusTurnId: !shouldPrepareBonusFusion,
      );
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
      skips: _game.fiesta?.skips[nextTeam.id] ?? 0,
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
  /// manche (scores, graine) et appliqué une seule fois par `nextRound`. Nul en
  /// Classique et après M3.
  RoundTransitionPlan? get _transitionPlan {
    final fiesta = _game.fiesta;
    if (fiesta == null) return null;
    return planRoundTransition(
      fiesta: fiesta,
      gameId: _game.gameId ?? '',
      finishedRound: _game.currentRound,
      scores: {for (final t in _teams) t.id: t.score},
      totalWords: _game.allWords.length,
      blockableTeamIds: _blockableTeamIds,
      continuingTeamId: getCurrentTeam()?.id,
    );
  }

  /// Équipes d'au moins 3 joueurs : celles qu'on peut viser avec « Bloquer un
  /// devineur ».
  Set<String> get _blockableTeamIds => {
        for (final t in _teams)
          if (canBlockGuesser(t.playerIds.length)) t.id,
      };

  /// Équipe qui ouvre la manche en cours par sa continuation : celle de la
  /// dernière entrée de la manche précédente. Nulle en M1.
  String? get _continuingTeamId => _game.currentRound <= 1
      ? null
      : _game.history
          .where((h) => h.round == _game.currentRound - 1)
          .lastOrNull
          ?.teamId;

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

  /// Modificateurs qui pèsent sur l'équipe qui joue (badges) : les règles de la
  /// manche COURANTE, continuation comprise, et ses malus reçus
  /// ([modifiersForTurn]).
  List<ModifierInstance> get currentTeamModifiers {
    final fiesta = _game.fiesta;
    final teamId = getCurrentTeam()?.id;
    if (fiesta == null || teamId == null) return const [];
    return modifiersForTurn(fiesta.active,
        teamId: teamId,
        playerId: getCurrentPlayer()?.id,
        round: _game.currentRound);
  }

  // ========== EFFETS DE TOUR (2-8) ==========

  FiestaTurnState get _turn => _game.fiesta?.turn ?? FiestaTurnState.empty;

  bool _has(String catalogId) =>
      currentTeamModifiers.any((m) => m.catalogId == catalogId);

  /// `no_pass` pèse sur l'équipe qui joue.
  bool get passBlocked => _has('no_pass');

  /// Passes gratuites du tour, et celles déjà utilisées : celles de la
  /// cartouche dépensée au départ du tour (une cartouche = un tour de N passes).
  int get freePasses => _charge('free_pass') == ChargeState.spent
      ? modifierById('free_pass')!.defaultCharges
      : 0;
  int get freePassesUsed => _turn.freePassesUsed;

  /// Il reste une passe gratuite ce tour. Toujours faux en Classique.
  bool get hasFreePass => freePassesUsed < freePasses;

  /// Cartouche Passe gratuite dépensée pour CE tour (badge du tour).
  bool get isFreePassOn => _charge('free_pass') == ChargeState.spent;

  /// Pénalité EFFECTIVE de la prochaine passe. Classique : la pénalité réglée.
  int get currentPassPenalty => hasFreePass ? 0 : _settings.passPenalty;

  /// 🔴 SEULE garde de la passe, sur la seconde affichée : `passWord` et le
  /// bouton de `turn_screen` la lisent tous deux, sinon le bouton s'affiche
  /// actif et le provider refuse (ou l'inverse).
  bool canPassWith(int displayedSeconds) =>
      !passBlocked && displayedSeconds >= currentPassPenalty;

  /// `one_answer` pèse sur l'équipe qui joue : une seule réponse par mot.
  bool get isOneAnswer => _has('one_answer');

  /// `reversed` : le mot du tour s'affiche à l'envers (tour seulement).
  bool get isWordReversed => _has('reversed');

  /// Devineur nommé à l'envoi qui ne répond pas CE tour (« Bloquer un
  /// devineur ») : nul s'il fait deviner, le blocage attend alors son prochain
  /// tour de devineur ([ModifierInstance.waitsFor]).
  Player? get blockedGuesser {
    final id = currentTeamModifiers
        .where((m) => m.catalogId == 'block_guesser')
        .firstOrNull
        ?.playerId;
    return id == null ? null : getPlayerById(id);
  }

  // ========== INTERDIT DE FAIRE DEVINER ==========

  /// Le blocage qui vise le joueur qui s'apprête à jouer, s'il y en a un. Jamais
  /// sur une continuation : le tour a déjà commencé.
  ModifierInstance? get _pendingGiverBlock {
    final fiesta = _game.fiesta;
    final team = getCurrentTeam();
    final player = getCurrentPlayer();
    if (fiesta == null || team == null || player == null || isContinuation) {
      return null;
    }
    return fiesta.active
        .where((m) =>
            m.catalogId == 'block_giver' &&
            m.fromTeamId != null &&
            m.teamId == team.id &&
            m.playerId == player.id)
        .firstOrNull;
  }

  /// Index du joueur de l'équipe qui joue, si son tour saute une fois de plus.
  int _indexAfterSkip(Team team) => playerIndexAtTurn(
        playerOrderForTeam: _game.playerOrderByTeam[team.id] ?? const [],
        cycleLength: _teams.length,
        turnIndex: _game.currentTurnIndex,
        skips: (_game.fiesta?.skips[team.id] ?? 0) + 1,
      );

  /// Ce que dit l'écran du piège : la phrase (tirage déterministe, elle ne change
  /// pas après une app tuée) et le joueur qui prend le téléphone.
  ({String phrase, String nextPlayer})? get giverBlockScreen {
    final block = _pendingGiverBlock;
    final team = getCurrentTeam();
    final blocked = getCurrentPlayer();
    if (block == null || team == null || blocked == null) return null;
    final next = team.playerIds[_indexAfterSkip(team)];
    return (
      phrase: giverBlockPhrase(
        seed: giverBlockSeed(_game.gameId ?? '', _game.currentTurnIndex),
        blocked: blocked.name,
        blocker: getPlayerById(block.fromPlayerId ?? '')?.name ??
            getTeamById(block.fromTeamId!)?.name ??
            '?',
      ),
      nextPlayer: getPlayerById(next)?.name ?? '',
    );
  }

  /// « Suivant » sur la phrase : le joueur saute ce tour, et son remplaçant
  /// repart de zéro. Tout ce qu'il avait allumé ou envoyé est annulé, cartouches
  /// rendues, et gardé pour [reuseReplacedChoices]. La rotation de son équipe se
  /// décale pour de bon : Alice, ~~Bob~~, Frank, Alice, Bob, Frank.
  void confirmGiverBlock() {
    if (_game.currentScreen != AppConstants.screenGiverBlocked) return;
    final block = _pendingGiverBlock;
    final team = getCurrentTeam();
    final player = getCurrentPlayer();
    var fiesta = _game.fiesta;
    if (block == null || team == null || player == null || fiesta == null) {
      _game = _game.copyWith(currentScreen: AppConstants.screenGame);
      notifyListeners();
      _saveGameState();
      return;
    }
    final sent = _sentBy(team.id);
    final bonuses = [
      for (final MapEntry(key: id, value: state) in fiesta.turn.charges.entries)
        if (state == ChargeState.armed) id,
    ];
    for (final m in sent) {
      fiesta = fiesta!.withoutSent(m);
    }
    final nextIndex = _indexAfterSkip(team);
    _game = _game.copyWith(
      currentScreen: AppConstants.screenGame,
      currentPlayerIndexInTeam: nextIndex,
      fiesta: fiesta!.copyWith(
        active: [...fiesta.active]..remove(block),
        skips: {...fiesta.skips, team.id: (fiesta.skips[team.id] ?? 0) + 1},
        turn: FiestaTurnState(
          replaced: bonuses.isEmpty && sent.isEmpty
              ? null
              : ReplacedChoices(
                  playerId: player.id, bonuses: bonuses, sent: sent),
        ),
      ),
    );
    notifyListeners();
    _saveGameState();
  }

  /// Joueur dont le remplaçant peut reprendre les choix (lien de l'avant-tour).
  Player? get replacedPlayer {
    final choices = _turn.replaced;
    return choices == null ? null : getPlayerById(choices.playerId);
  }

  /// Remet ce que le joueur bloqué avait préparé, tout ce qui reste possible.
  void reuseReplacedChoices() {
    final fiesta = _game.fiesta;
    final choices = _turn.replaced;
    if (fiesta == null || choices == null || !_inPreTurn) return;
    _game = _game.copyWith(
        fiesta:
            fiesta.copyWith(turn: fiesta.turn.copyWith(clearReplaced: true)));
    for (final id in choices.bonuses) {
      _setCharge(id, true);
    }
    for (final m in choices.sent) {
      inflictMalus(m.catalogId, m.teamId!, playerId: m.playerId);
    }
    notifyListeners();
    _saveGameState();
  }

  // ========== BONUS À CHARGE : ×2 (2-9), DEUX MOTS (2-11), +10 S ==========
  // Une table (`kChargeBonusKeys`), une implémentation : chaque getter public
  // n'est qu'un id de catalogue.

  /// Modificateurs EN JEU pendant le tour (badges du tour, tags analytics) :
  /// règles de manche et malus reçus. Un bonus activé a son badge à part
  /// ([spentBonuses]).
  List<ModifierInstance> get turnModifiers => currentTeamModifiers;

  /// Bonus dépensés pour CE tour (badges du tour), dans l'ordre de la table.
  List<String> get spentBonuses => [
        for (final id in kChargeBonusKeys.keys)
          if (_charge(id) == ChargeState.spent) id,
      ];

  ChargeState? _charge(String id) => _turn.charges[id];

  /// Cartouches [id] restantes de l'équipe qui joue pour le reste de la partie
  /// (un bonus allumé compte encore, il se dépense au départ).
  int _chargesLeft(String id) {
    final fiesta = _game.fiesta;
    final teamId = getCurrentTeam()?.id;
    if (fiesta == null || teamId == null) return 0;
    return fiesta.cartridgesLeft(id, teamId);
  }

  /// Pourquoi le bonus [id] ne peut pas s'allumer ce tour (`null` = il
  /// peut) : déjà en jeu, ou incompatible avec un modificateur du tour (règle de
  /// manche, malus reçu) ou un autre bonus allumé. Pas de plafond : seules les
  /// incompatibilités limitent.
  String? _conflict(String id) {
    for (final other in [
      ...turnModifiers.map((m) => m.catalogId),
      ...kChargeBonusKeys.keys
          .where((other) => other != id && _charge(other) != null),
    ]) {
      if (other == id) return 'déjà en jeu ce tour';
      if (!areCompatible(other, id)) {
        return 'incompatible avec ${modifierById(other)!.name} ce tour';
      }
    }
    return null;
  }

  bool _blocked(String id) => _conflict(id) != null;

  /// Interrupteur d'un bonus à charge, avant le départ : seul `armed` est
  /// écrit ; la charge se dépense dans `startTurnTimer`.
  void _setCharge(String id, bool on) {
    final fiesta = _game.fiesta;
    if (fiesta == null ||
        _charge(id) == ChargeState.spent ||
        (on && (_chargesLeft(id) <= 0 || _blocked(id)))) {
      return;
    }
    _game = _game.copyWith(
      fiesta: fiesta.copyWith(
          turn: fiesta.turn.withCharge(id, on ? ChargeState.armed : null)),
    );
    notifyListeners();
    _saveGameState();
  }

  /// Bonus allumé pour le prochain départ, donc encore annulable (dépensé sur
  /// la première partie d'un tour continué : non).
  bool isBonusArmed(String id) => _charge(id) == ChargeState.armed;

  /// Interrupteur de l'avant-tour allumé (ou charge déjà dépensée).
  bool get isDoublePointsArmed => _charge('double_points') != null;

  /// Les points de CE tour comptent ×2 : charge dépensée au départ. Vaut aussi
  /// pour la continuation de fin de manche, qui est le même tour.
  bool get isDoublePointsOn => _charge('double_points') == ChargeState.spent;
  int get doublePointsLeft => _chargesLeft('double_points');
  bool get doublePointsBlocked => _blocked('double_points');
  void setDoublePoints(bool on) => _setCharge('double_points', on);

  /// Deux mots à l'écran pendant CE tour (continuation comprise).
  bool get isTwoWordsArmed => _charge('two_words') != null;

  /// Deux cartes à l'écran : cartouche dépensée.
  bool get isTwoWordsOn => _charge('two_words') == ChargeState.spent;
  int get twoWordsLeft => _chargesLeft('two_words');
  bool get twoWordsBlocked => _blocked('two_words');
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

  /// Fiesta à la VRAIE fin d'un tour : état du tour vidé, malus infligés à
  /// l'équipe consommés, sauf les blocages qui attendent. 🔴 Une fin de manche n'en est pas une : la continuation
  /// en N+1 est le même tour. Nul en Classique.
  FiestaState? _fiestaAfterTurn() {
    final fiesta = _game.fiesta;
    if (fiesta == null || _teams.isEmpty) return null;
    final teamId = _teams[_game.currentTeamIndex].id;
    final playerId = getCurrentPlayer()?.id;
    return fiesta.copyWith(
      turn: FiestaTurnState.empty,
      active: fiesta.active
          // Malus infligés à l'équipe : ils visaient CE tour (sans effet s'ils
          // étaient interdits dans sa manche).
          .where((m) =>
              m.fromTeamId == null ||
              m.teamId != teamId ||
              m.waitsFor(playerId))
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

  // ========== ACTIF CE TOUR / RÉSERVE ==========
  // Une cartouche = UN tour d'UNE équipe. Bonus : allumé avant le tour,
  // dépensé au départ du chrono (`startTurnTimer`). Malus : infligé à une
  // autre équipe pour SON prochain tour, dépensé tout de suite (`ChargeUse`
  // avec cible), annulable tant que le tour de l'équipe qui l'envoie n'a pas
  // commencé. Tout vit dans `GameState.fiesta` (kill, retour arrière).

  /// Règles de manche qui pèsent sur ce tour (« Ce tour », cercles neutres).
  List<ModifierInstance> get roundRulesThisTurn =>
      currentTeamModifiers.where((m) => m.fromTeamId == null).toList();

  /// Malus infligés par une autre équipe pour ce tour.
  List<ModifierInstance> get receivedThisTurn =>
      currentTeamModifiers.where((m) => m.fromTeamId != null).toList();

  /// Bonus allumés pour ce tour (ou déjà dépensés), dans l'ordre d'allumage.
  List<String> get bonusesThisTurn => _turn.charges.keys.toList();

  /// Réserve de l'équipe qui joue, dans l'ordre du catalogue : ses
  /// cartouches pour la partie, bonus et malus, épuisées comprises (un bonus
  /// allumé a quitté la réserve). Une cartouche impossible dans la manche
  /// (un mime avant M3) est cachée. Vide hors Fiesta. Continuation : la même
  /// réserve ; un bonus dépensé sur la partie d'avant reste en cours, ni
  /// recompté ni rallumable.
  List<Cartridge> get reserve {
    final fiesta = _game.fiesta;
    final teamId = getCurrentTeam()?.id;
    if (fiesta == null || teamId == null) return const [];
    return [
      for (final def in kModifierCatalog)
        if (isEligibleForRound(def, _game.currentRound) &&
            fiesta.cartridgesOwned(def.id, teamId) > 0)
          Cartridge(
            def.id,
            left: _chargesLeft(def.id) - (isBonusArmed(def.id) ? 1 : 0),
            blockedReason: def.nature == ModifierNature.bonus
                ? switch (_charge(def.id)) {
                    ChargeState.spent => 'déjà en cours ce tour',
                    ChargeState.armed => null,
                    null => _conflict(def.id),
                  }
                : _malusBlock(def),
          ),
    ];
  }

  /// Pourquoi le malus [def] ne peut pas être infligé ce tour : la règle de
  /// manche le rend inutile (même modificateur, ou incompatible : un seul
  /// mime à la fois), ou personne ne peut le recevoir.
  String? _malusBlock(ModifierDef def) {
    for (final rule in roundRulesThisTurn) {
      if (rule.catalogId == def.id) return 'déjà en jeu pour tous cette manche';
      if (!areCompatible(rule.catalogId, def.id)) {
        return 'incompatible avec ${modifierById(rule.catalogId)!.name} '
            'cette manche';
      }
    }
    if (targetsFor(def.id).isEmpty) {
      return 'aucune équipe adverse n\'a 3 joueurs';
    }
    return null;
  }

  /// Allume / éteint le bonus [id] de la réserve pour ce tour.
  void toggleBonus(String id) => _setCharge(id, _charge(id) == null);

  /// Équipes que l'équipe qui joue peut viser avec le malus [catalogId] :
  /// toutes les autres (« Bloquer un devineur » : 3 joueurs ou plus).
  List<Team> targetsFor(String catalogId) {
    final me = getCurrentTeam()?.id;
    return [
      for (final t in _teams)
        if (t.id != me &&
            (catalogId != 'block_guesser' ||
                canBlockGuesser(t.playerIds.length)))
          t,
    ];
  }

  /// Avant-tour, continuation comprise : seul moment où la réserve se joue.
  bool get _inPreTurn =>
      _game.fiesta != null && _game.currentScreen == AppConstants.screenGame;

  /// Inflige le malus [catalogId] de la réserve de l'équipe qui joue à
  /// [targetTeamId], pour le PROCHAIN tour de celle-ci ; un blocage nomme le
  /// joueur [playerId]. Rend le message de refus si ce malus (ou un malus qui ne
  /// s'y cumule pas) lui est déjà infligé pour ce tour-là : rien n'est alors
  /// consommé. Hors avant-tour, cartouche épuisée ou grisée, cible invalide :
  /// ignoré (`null`).
  String? inflictMalus(String catalogId, String targetTeamId,
      {String? playerId}) {
    final fiesta = _game.fiesta;
    final me = getCurrentTeam();
    final def = modifierById(catalogId);
    final cartridge =
        reserve.where((c) => c.catalogId == catalogId).firstOrNull;
    if (!_inPreTurn ||
        me == null ||
        def == null ||
        def.nature != ModifierNature.malus ||
        cartridge == null ||
        !cartridge.usable ||
        !targetsFor(catalogId).any((t) => t.id == targetTeamId) ||
        (def.defaultTarget == ModifierTarget.player &&
            !getTeamById(targetTeamId)!.playerIds.contains(playerId))) {
      return null;
    }
    final target = getTeamById(targetTeamId)!.name;
    for (final m in fiesta!.active) {
      if (m.fromTeamId == null || m.teamId != targetTeamId) continue;
      final by = getTeamById(m.fromTeamId!)?.name ?? '?';
      if (m.catalogId == catalogId) {
        return 'Impossible : ${def.name} est déjà infligé à l\'équipe $target '
            'par l\'équipe $by pour son prochain tour. Choisis un autre malus '
            'ou attends.';
      }
      if (!areCompatible(m.catalogId, catalogId)) {
        return 'Impossible : ${def.name} ne se cumule pas avec '
            '${modifierById(m.catalogId)!.name}, déjà infligé à l\'équipe '
            '$target par l\'équipe $by pour son prochain tour. Choisis un '
            'autre malus ou attends.';
      }
    }
    final round = _game.currentRound;
    _game = _game.copyWith(
      fiesta: fiesta.copyWith(
        active: [
          ...fiesta.active,
          ModifierInstance(
            catalogId: catalogId,
            scope: ModifierScope.turn,
            target: def.defaultTarget == ModifierTarget.player
                ? ModifierTarget.player
                : ModifierTarget.team,
            teamId: targetTeamId,
            playerId: playerId,
            charges: def.defaultCharges,
            nature: ModifierNature.malus,
            round: round,
            fromTeamId: me.id,
            fromPlayerId: getCurrentPlayer()?.id,
            sentTurnIndex: _game.currentTurnIndex,
          ),
        ],
        chargesUsed: [
          ...fiesta.chargesUsed,
          ChargeUse(
              catalogId: catalogId,
              teamId: me.id,
              round: round,
              targetTeamId: targetTeamId,
              turn: _game.currentTurn),
        ],
      ),
    );
    notifyListeners();
    _saveGameState();
    return null;
  }

  /// Malus envoyés par l'équipe qui joue, annulables tant que son tour n'a
  /// pas commencé (pastilles « Envoyé »). Vide hors avant-tour. Tour et manche
  /// d'envoi = les courants : sur une continuation, ce qui a été envoyé avant la
  /// première partie du tour est déjà parti, plus annulable ; un blocage qui
  /// attend depuis un tour précédent aussi.
  List<ModifierInstance> get sentThisTurn {
    final me = getCurrentTeam()?.id;
    if (!_inPreTurn || me == null) return const [];
    return _sentBy(me);
  }

  List<ModifierInstance> _sentBy(String teamId) => _game.fiesta!.active
      .where((m) =>
          m.fromTeamId == teamId &&
          m.round == _game.currentRound &&
          m.sentTurnIndex == _game.currentTurnIndex)
      .toList();

  /// Annule l'envoi de [sent] (une entrée de [sentThisTurn]) : le malus
  /// quitte sa cible, la cartouche revient dans la réserve.
  void cancelSent(ModifierInstance sent) {
    if (!sentThisTurn.contains(sent)) return;
    _game = _game.copyWith(fiesta: _game.fiesta!.withoutSent(sent));
    notifyListeners();
    _saveGameState();
  }

  /// Récap « Modificateurs de la partie », en faits (archivés). Vide en
  /// Classique.
  List<ModifierRecapItem> get _modifierRecapItems {
    final fiesta = _game.fiesta;
    if (fiesta == null) return const [];
    return buildModifierRecap(
      rules: fiesta.rules,
      chargesUsed: fiesta.chargesUsed,
      earned: fiesta.earned,
      gameId: _game.gameId ?? '',
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
      mode: _game.fiesta == null ? null : kFiestaModeId,
      modifierRecap: _game.fiesta == null ? null : _modifierRecapItems,
      setup: GameSetupSnapshot(
        settings: _settings.copyWith(),
        fiesta: _game.fiesta?.rules,
      ),
      playOrder: [
        for (final i in _game.teamPlayOrder.take(_teams.length))
          if (i < _teams.length) _teams[i].id,
      ],
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

  /// Fin de la révélation des scores : l'écran Résultats prend sa place, et
  /// elle ne se rejouera plus pour cette partie.
  void markScoreRevealSeen() {
    if (_game.scoreRevealSeen) return;
    _game = _game.copyWith(scoreRevealSeen: true);
    notifyListeners();
    _saveGameState();
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
    _pendingFiesta = await _rememberedFiesta();
    notifyListeners();
  }

  // Rejouer avec mêmes joueurs → efface mots, reset scores, va aux paramètres,
  // avec la config Fiesta de la partie finie en attente (Q12).
  Future<void> restartWithSamePlayers() async {
    // 🔴 Lire AVANT `GameState.initial()` ci-dessous, qui efface `fiesta`.
    // Sans partie jouée (Rejouer de l'accueil, après `endGameAndGoHome`), la
    // config déjà en mémoire fait foi.
    if (_game.allWords.isNotEmpty) _pendingFiesta = _game.fiesta?.rules;
    _rememberFiestaChoice(replay: true);

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
      final indexA = _teams.indexWhere((t) => t.id == a.id);
      final indexB = _teams.indexWhere((t) => t.id == b.id);
      return compareFinalRank(
        scoreA: a.score,
        scoreB: b.score,
        startA: _game.teamPlayOrder.indexOf(indexA),
        startB: _game.teamPlayOrder.indexOf(indexB),
      );
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
  bool get canGoBackToVerification => _restorableSnapshot != null;

  /// Le `game` du snapshot de retour arrière, s'il est restaurable : écrit à
  /// plat par l'ancienne version, corrompu, ou Fiesta illisible (forme v1 :
  /// il serait restauré en Classique) → `null`, on renonce au retour arrière.
  Map<String, dynamic>? get _restorableSnapshot {
    final gameJson = _game.preValidationSnapshot?['game'];
    if (gameJson is! Map<String, dynamic> ||
        GameState.hasUnreadableFiesta(gameJson)) {
      return null;
    }
    return gameJson;
  }

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
    // Snapshot non restaurable ([_restorableSnapshot]) : on renonce au retour
    // arrière plutôt que de crasher ou de repartir en Classique, sans rien
    // muter. L'utilisateur perd la possibilité de revenir sur CE tour.
    final gameJson = _restorableSnapshot;
    if (snapshot == null || gameJson == null) return;

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
      // Le snapshot précède la révélation : une correction ne la rejoue pas.
      scoreRevealSeen: _game.scoreRevealSeen,
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
