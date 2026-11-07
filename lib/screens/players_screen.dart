import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../models/word_stats.dart';
import '../utils/constants.dart';
import '../utils/word_categories/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/effects/shooting_stars.dart';
import '../widgets/help/coach_marks.dart';
import '../widgets/help/help_button.dart';
import '../widgets/help/help_content.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

/// 20 lignes au plus ([AppConstants.maxPlayers]), moins de 100 px chacune.
const double _allRowsCacheExtent = 2000;

class _PlayersScreenState extends State<PlayersScreen> {
  final _firstPlayerKey = GlobalKey();
  final _wordsKey = GlobalKey();
  final _nextKey = GlobalKey();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _errors = {};
  bool _isInitialized = false;

  // Pool de mots pré-générés avec métadonnées (mode aléatoire)
  Map<String, WordMetadata>? _wordPool;
  List<String>? _availableWords;

  // Cache des settings utilisés pour générer le pool (pour détecter les changements)
  int? _cachedTotalWords;
  List<String>? _cachedCategories;
  List<int>? _cachedDifficulties;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPlayersWithSettings();
    });
  }

  Future<void> _syncPlayersWithSettings() async {
    final provider = context.read<GameProvider>();
    final settings = provider.settings;

    // 1. Ajuster le nombre de joueurs si nécessaire
    while (provider.players.length < settings.numberOfPlayers) {
      provider.addPlayer(provider.nextSavedName ?? '', allowEmpty: true);
    }
    while (provider.players.length > settings.numberOfPlayers) {
      provider.removePlayer(provider.players.last.id);
    }

    // 2. Synchroniser les contrôleurs avec les joueurs existants
    final currentPlayerIds = provider.players.map((p) => p.id).toSet();

    // Supprimer les contrôleurs et FocusNodes pour les joueurs qui n'existent plus
    final idsToRemove = _controllers.keys
        .where((id) => !currentPlayerIds.contains(id))
        .toList();
    for (final id in idsToRemove) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
      _focusNodes[id]?.dispose();
      _focusNodes.remove(id);
    }

    // Créer des contrôleurs et FocusNodes pour les nouveaux joueurs
    for (final player in provider.players) {
      if (!_controllers.containsKey(player.id)) {
        _controllers[player.id] = TextEditingController(text: player.name);
      }
      if (!_focusNodes.containsKey(player.id)) {
        _focusNodes[player.id] = FocusNode();
      }
    }

    // 3. En mode aléatoire : générer/compléter les mots pour TOUS les joueurs
    if (settings.wordChoice == AppConstants.wordChoiceRandom) {
      // Vérifier si les settings ont changé (invalider le cache si nécessaire)
      final settingsChanged = _wordPool != null &&
          (_cachedTotalWords != settings.totalWords ||
              !_listEquals(_cachedCategories, settings.selectedCategories) ||
              !_listEquals(
                  _cachedDifficulties, settings.selectedDifficultyLevels));

      if (settingsChanged) {
        print('[WordPool] Settings changed, invalidating cache');
        _wordPool = null;
        _availableWords = null;
      }

      // Pré-générer le pool de mots avec métadonnées
      if (_wordPool == null) {
        _wordPool = await generateWordsWithMetadataAsync(
          settings.selectedCategories,
          settings.totalWords,
          difficultyLevels: settings.selectedDifficultyLevels,
        );
        _availableWords = _wordPool!.keys.toList()..shuffle();
        // Stocker le cache dans GameProvider
        provider.setWordMetadataCache(_wordPool!);
        // Mémoriser les settings utilisés
        _cachedTotalWords = settings.totalWords;
        _cachedCategories = List.from(settings.selectedCategories);
        _cachedDifficulties = List.from(settings.selectedDifficultyLevels);
      }

      for (final player in provider.players) {
        final wordsNeeded = provider.getWordsCountForPlayer(player.id);
        await _ensureWordsForPlayer(player.id, provider, wordsNeeded);
      }
    } else {
      // 4. En mode personnalisé : tronquer si trop de mots
      for (final player in provider.players) {
        final wordsNeeded = provider.getWordsCountForPlayer(player.id);
        if (player.words.length > wordsNeeded) {
          provider.updatePlayerWords(
            player.id,
            player.words.take(wordsNeeded).toList(),
          );
        }
      }
    }

    if (!_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // Génère/complète les mots pour atteindre le nombre requis
  Future<void> _ensureWordsForPlayer(
      String playerId, GameProvider provider, int wordsNeeded) async {
    final player = provider.players.firstWhere((p) => p.id == playerId);

    if (player.words.length >= wordsNeeded) {
      // Tronquer si trop de mots
      if (player.words.length > wordsNeeded) {
        provider.updatePlayerWords(
            playerId, player.words.take(wordsNeeded).toList());
      }
      return;
    }

    // Compléter les mots manquants
    final otherPlayersWords = _getOtherPlayersWords(provider, playerId);
    final newWords = <String>[...player.words];

    while (newWords.length < wordsNeeded) {
      final word =
          await _generateUniqueWord(provider, otherPlayersWords, newWords);
      if (word != null) {
        newWords.add(word);
      } else {
        break; // Plus de mots disponibles
      }
    }

    if (newWords.length != player.words.length) {
      provider.updatePlayerWords(playerId, newWords);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // Vérifie si un nom est en doublon
  String? _getErrorForPlayer(String playerId, GameProvider provider) {
    final controller = _controllers[playerId];
    if (controller == null) return null;

    final name = controller.text.trim();
    if (name.isEmpty)
      return null; // Pas d'erreur affichée si vide (juste le bouton grisé)

    // Vérifier les doublons
    int count = 0;
    for (final player in provider.players) {
      final otherController = _controllers[player.id];
      if (otherController != null && otherController.text.trim() == name) {
        count++;
      }
    }

    if (count > 1) return 'Doublon';
    return _errors[playerId];
  }

  // Vérifie si le bouton Suivant peut être activé
  bool _canProceed(GameProvider provider) {
    if (!_isInitialized) return false;

    final names = <String>[];

    for (final player in provider.players) {
      final controller = _controllers[player.id];
      if (controller == null) return false;

      final name = controller.text.trim();

      // Tous les noms doivent être remplis
      if (name.isEmpty) return false;

      // Pas de doublons
      if (names.contains(name)) return false;
      names.add(name);

      // Tous les mots doivent être remplis
      final wordsNeeded = provider.getWordsCountForPlayer(player.id);
      if (player.words.length < wordsNeeded) return false;
    }

    return true;
  }

  void _saveAndContinue(GameProvider provider) {
    // Sauvegarder les noms
    for (final player in provider.players) {
      final name = _controllers[player.id]?.text.trim() ?? '';
      provider.updatePlayer(player.id, name: name);
    }

    provider.cleanupEmptyPlayers();

    // Si des équipes existent déjà, synchroniser avec les joueurs actuels
    // Sinon, créer de nouvelles équipes
    if (provider.teams.isNotEmpty) {
      provider.syncTeamsWithPlayers();
    } else {
      provider.createTeams();
      provider.randomizeTeams();
    }

    provider.goToScreen(AppConstants.screenTeams);
  }

  // Récupère tous les mots déjà utilisés par les autres joueurs
  Set<String> _getOtherPlayersWords(
      GameProvider provider, String currentPlayerId) {
    final otherWords = <String>{};
    for (final p in provider.players) {
      if (p.id != currentPlayerId) {
        otherWords.addAll(p.words.map((w) => w.toLowerCase()));
      }
    }
    return otherWords;
  }

  // Génère un mot unique qui n'est pas utilisé
  Future<String?> _generateUniqueWord(
    GameProvider provider,
    Set<String> otherPlayersWords,
    List<String> currentModalWords,
  ) async {
    // Utiliser le pool pré-généré si disponible (mode aléatoire optimisé)
    if (_availableWords != null && _availableWords!.isNotEmpty) {
      for (int i = 0; i < _availableWords!.length; i++) {
        final word = _availableWords![i];
        final wordLower = word.toLowerCase();
        if (!otherPlayersWords.contains(wordLower) &&
            !currentModalWords
                .map((w) => w.toLowerCase())
                .contains(wordLower)) {
          _availableWords!.removeAt(i);
          return word;
        }
      }
      return null; // Plus de mots uniques disponibles
    }

    // Repli quand le pool pré-chargé est épuisé.
    //
    // 🔴 C'était un copier-coller de la boucle à 100 tentatives de
    // `words_screen` : un tirage complet du corpus par essai, rejeté si le mot
    // était déjà pris. Le générateur sait maintenant exclure, donc un appel
    // suffit et le cas « plus rien de disponible » se voit tout de suite.
    final tirage = await generateWordsFromCategoriesAsync(
      provider.settings.selectedCategories,
      1,
      difficultyLevels: provider.settings.selectedDifficultyLevels,
      exclude: {...otherPlayersWords, ...currentModalWords},
    );
    if (tirage.isNotEmpty) return tirage.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final canProceed = _canProceed(provider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    // Retour système (Android) = bouton retour, pas la sortie de l'app.
    void back() {
      // Sauvegarder les noms actuels avant de partir
      for (final player in provider.players) {
        final name = _controllers[player.id]?.text.trim() ?? '';
        if (name != player.name) {
          provider.updatePlayer(player.id, name: name);
        }
      }
      provider.goToScreen(AppConstants.screenSettings);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: ShootingStars(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  Text(
                    'Joueurs',
                    style: AppTextStyles.subtitle(fontSize: 40),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isInitialized
                        ? ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 24,
                              bottom: 16,
                            ),
                            // Toutes les lignes attachées : « suivant » au
                            // clavier donne le focus même à une ligne éloignée.
                            cacheExtent: _allRowsCacheExtent,
                            itemCount: provider.players.length,
                            itemBuilder: (context, index) {
                              final player = provider.players[index];
                              final error =
                                  _getErrorForPlayer(player.id, provider);
                              final wordsCount = player.words.length;
                              final wordsNeeded =
                                  provider.getWordsCountForPlayer(player.id);
                              final isWordsFilled = wordsCount >= wordsNeeded;
                              final playerName =
                                  _controllers[player.id]?.text.trim() ?? '';
                              final hasName = playerName.isNotEmpty;
                              // Mode aléatoire : les mots tirés restent cachés,
                              // la carte affiche un badge non cliquable.
                              final isRandom = provider.settings.wordChoice ==
                                  AppConstants.wordChoiceRandom;

                              final isLastPlayer =
                                  index == provider.players.length - 1;
                              final nextPlayerId = isLastPlayer
                                  ? null
                                  : provider.players[index + 1].id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      key: index == 0 ? _firstPlayerKey : null,
                                      child: AppInput(
                                        key: ValueKey('input_${player.id}'),
                                        controller: _controllers[player.id],
                                        focusNode: _focusNodes[player.id],
                                        placeholder: 'Joueur ${index + 1}',
                                        error: error,
                                        textInputAction: isLastPlayer
                                            ? TextInputAction.done
                                            : TextInputAction.next,
                                        onSubmitted: isLastPlayer
                                            ? () =>
                                                FocusScope.of(context).unfocus()
                                            : () {
                                                if (nextPlayerId != null) {
                                                  _focusNodes[nextPlayerId]
                                                      ?.requestFocus();
                                                }
                                              },
                                        onChanged: (value) {
                                          setState(
                                              () {}); // Rafraîchir pour vérifier les doublons
                                          // Sauvegarder le nom immédiatement
                                          provider.updatePlayer(player.id,
                                              name: value.trim());
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      key: index == 0 ? _wordsKey : null,
                                      onTap: hasName && !isRandom
                                          ? () {
                                              provider.setCurrentEditingPlayer(
                                                  player.id);
                                              provider.goToScreen(
                                                  AppConstants.screenWords);
                                            }
                                          : null,
                                      child: Opacity(
                                        opacity:
                                            hasName || isRandom ? 1.0 : 0.4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isWordsFilled
                                                ? AppColors.success
                                                    .withOpacity(0.2)
                                                : AppColors.error
                                                    .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isWordsFilled
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isWordsFilled
                                                    ? Icons.check_circle
                                                    : Icons.edit_note,
                                                size: 18,
                                                color: isWordsFilled
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isRandom
                                                    ? '$wordsCount mots prêts'
                                                    : isWordsFilled
                                                        ? 'Voir mots'
                                                        : 'Saisir mots',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isWordsFilled
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                              ),
                                              if (!isRandom) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 16,
                                                  color: isWordsFilled
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.secondaryCyan),
                          ),
                  ),
                  // Clavier ouvert (il cachait déjà ce bouton) : la liste
                  // s'arrête au clavier, et le champ y remonte de lui-même
                  // (`EditableText` le garde visible dans sa liste). L'écran
                  // n'a pas de Scaffold pour le faire.
                  if (keyboard > 0)
                    SizedBox(height: keyboard)
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: AppButton(
                        key: _nextKey,
                        text: 'Suivant',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        fullWidth: true,
                        disabled: !canProceed,
                        onPressed: canProceed
                            ? () => _saveAndContinue(provider)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            AppBackButton(onPressed: back),
            HelpButton(
              onPressed: () => CoachMarks.show(
                context,
                playersHelp(
                  firstPlayer: _firstPlayerKey,
                  words: _wordsKey,
                  next: _nextKey,
                  randomWords: provider.settings.wordChoice ==
                      AppConstants.wordChoiceRandom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compare deux listes pour l'égalité (ordre et contenu)
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
