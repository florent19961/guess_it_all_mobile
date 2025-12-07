import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/word_categories.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_modal.dart';
import '../widgets/effects/shooting_stars.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _errors = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPlayersWithSettings();
    });
  }

  void _syncPlayersWithSettings() {
    final provider = context.read<GameProvider>();
    final settings = provider.settings;

    // 1. Ajuster le nombre de joueurs si nécessaire
    while (provider.players.length < settings.numberOfPlayers) {
      provider.addPlayer('', allowEmpty: true);
    }
    while (provider.players.length > settings.numberOfPlayers) {
      provider.removePlayer(provider.players.last.id);
    }

    // 2. Synchroniser les contrôleurs avec les joueurs existants
    final currentPlayerIds = provider.players.map((p) => p.id).toSet();

    // Supprimer les contrôleurs pour les joueurs qui n'existent plus
    final idsToRemove = _controllers.keys
        .where((id) => !currentPlayerIds.contains(id))
        .toList();
    for (final id in idsToRemove) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
    }

    // Créer des contrôleurs pour les nouveaux joueurs
    for (final player in provider.players) {
      if (!_controllers.containsKey(player.id)) {
        _controllers[player.id] = TextEditingController(text: player.name);
      }
    }

    // 3. En mode aléatoire : générer/compléter les mots pour TOUS les joueurs
    if (settings.wordChoice == AppConstants.wordChoiceRandom) {
      for (final player in provider.players) {
        _ensureWordsForPlayer(player.id, provider, settings.wordsPerPlayer);
      }
    } else {
      // 4. En mode personnalisé : tronquer si trop de mots
      for (final player in provider.players) {
        if (player.words.length > settings.wordsPerPlayer) {
          provider.updatePlayerWords(
            player.id,
            player.words.take(settings.wordsPerPlayer).toList(),
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
  void _ensureWordsForPlayer(
      String playerId, GameProvider provider, int wordsNeeded) {
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
      final word = _generateUniqueWord(provider, otherPlayersWords, newWords);
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
      if (player.words.length < provider.settings.wordsPerPlayer) return false;
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
    provider.createTeams();
    provider.randomizeTeams();
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
  String? _generateUniqueWord(
    GameProvider provider,
    Set<String> otherPlayersWords,
    List<String> currentModalWords,
  ) {
    int attempts = 0;
    while (attempts < 100) {
      final words = generateWordsFromCategories(
        provider.settings.selectedCategories,
        1,
        difficultyLevels: provider.settings.selectedDifficultyLevels,
      );
      if (words.isNotEmpty) {
        final word = words[0];
        final wordLower = word.toLowerCase();
        // Vérifier que le mot n'est pas utilisé par d'autres joueurs ni dans le modal actuel
        if (!otherPlayersWords.contains(wordLower) &&
            !currentModalWords
                .map((w) => w.toLowerCase())
                .contains(wordLower)) {
          return word;
        }
      }
      attempts++;
    }
    return null;
  }

  void _showNoWordsAvailableWarning(BuildContext context) {
    AppModal.show(
      context,
      title: 'Oups !',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aucun mot n\'est plus disponible, tu dois en créer un toi-même !',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Compris',
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPartialFillWarning(BuildContext context, int filled, int needed) {
    final remaining = needed - filled;
    AppModal.show(
      context,
      title: 'Attention',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Il ne reste que $filled mot${filled > 1 ? 's' : ''} disponible${filled > 1 ? 's' : ''} '
            'et tu dois en remplir $needed.\n\n'
            'Il te faudra compléter les $remaining restant${remaining > 1 ? 's' : ''} toi-même !',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Compris',
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showWordsModal(
      BuildContext context, Player player, GameProvider provider) {
    final wordsPerPlayer = provider.settings.wordsPerPlayer;
    final wordControllers = <TextEditingController>[];

    // Initialiser les contrôleurs avec les mots existants
    for (int i = 0; i < wordsPerPlayer; i++) {
      final existingWord = i < player.words.length ? player.words[i] : '';
      wordControllers.add(TextEditingController(text: existingWord));
    }

    // Mots des autres joueurs (excluant le joueur actuel)
    final otherPlayersWords = _getOtherPlayersWords(provider, player.id);

    // Fonction pour vérifier si un mot est en doublon
    String? getWordError(int index) {
      final word = wordControllers[index].text.trim();
      if (word.isEmpty) return null;

      final wordLower = word.toLowerCase();

      // Vérifier si le mot est utilisé par un autre joueur
      if (otherPlayersWords.contains(wordLower)) {
        return 'Mot déjà pris par un autre joueur';
      }

      // Vérifier si le mot est en doublon dans le modal actuel
      for (int i = 0; i < wordControllers.length; i++) {
        if (i != index) {
          final otherWord = wordControllers[i].text.trim().toLowerCase();
          if (otherWord == wordLower) {
            return 'Doublon';
          }
        }
      }

      return null;
    }

    // Fonction pour vérifier si on peut valider
    bool canValidate() {
      for (int i = 0; i < wordControllers.length; i++) {
        if (getWordError(i) != null) return false;
      }
      return true;
    }

    AppModal.show(
      context,
      title: 'Mots de ${player.name.isNotEmpty ? player.name : "Joueur"}',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isValid = canValidate();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton "Grosse flemme"
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppButton(
                  text: 'Grosse flemme 😴',
                  variant: AppButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {
                    // Compter les champs vides avant remplissage
                    final emptyFieldsCount = wordControllers
                        .where((c) => c.text.trim().isEmpty)
                        .length;

                    if (emptyFieldsCount == 0) return; // Rien à remplir

                    int filledCount = 0;
                    setModalState(() {
                      // Collecter les mots déjà remplis dans le modal
                      final filledWords = wordControllers
                          .map((c) => c.text.trim())
                          .where((w) => w.isNotEmpty)
                          .toList();

                      // Remplir tous les champs vides
                      for (int i = 0; i < wordControllers.length; i++) {
                        if (wordControllers[i].text.trim().isEmpty) {
                          final newWord = _generateUniqueWord(
                            provider,
                            otherPlayersWords,
                            filledWords,
                          );
                          if (newWord != null) {
                            wordControllers[i].text = newWord;
                            filledWords.add(newWord);
                            filledCount++;
                          }
                        }
                      }
                    });

                    // Afficher le message approprié
                    if (filledCount == 0) {
                      // Aucun mot n'a pu être généré
                      _showNoWordsAvailableWarning(context);
                    } else if (filledCount < emptyFieldsCount) {
                      // Seulement une partie a été remplie
                      _showPartialFillWarning(
                          context, filledCount, emptyFieldsCount);
                    }
                  },
                ),
              ),
              ...List.generate(wordsPerPlayer, (index) {
                final error = getWordError(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppInput(
                          controller: wordControllers[index],
                          placeholder: 'Mot ${index + 1}',
                          error: error,
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Mots actuels dans le modal (sauf celui qu'on remplace)
                          final currentModalWords = wordControllers
                              .asMap()
                              .entries
                              .where((e) => e.key != index)
                              .map((e) => e.value.text.trim())
                              .where((w) => w.isNotEmpty)
                              .toList();

                          final newWord = _generateUniqueWord(
                            provider,
                            otherPlayersWords,
                            currentModalWords,
                          );

                          if (newWord != null) {
                            setModalState(() {
                              wordControllers[index].text = newWord;
                            });
                          } else {
                            _showNoWordsAvailableWarning(context);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shuffle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              AppButton(
                text: 'Valider',
                variant: AppButtonVariant.primary,
                fullWidth: true,
                disabled: !isValid,
                onPressed: isValid
                    ? () {
                        // Sauvegarder les mots
                        final words = wordControllers
                            .map((c) => c.text.trim())
                            .where((w) => w.isNotEmpty)
                            .toList();
                        provider.updatePlayerWords(player.id, words);

                        // Disposer les contrôleurs
                        for (final controller in wordControllers) {
                          controller.dispose();
                        }

                        Navigator.of(context).pop();
                        setState(() {}); // Mettre à jour l'écran principal
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final canProceed = _canProceed(provider);

    return ShootingStars(
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
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: provider.players.length,
                          itemBuilder: (context, index) {
                            final player = provider.players[index];
                            final error =
                                _getErrorForPlayer(player.id, provider);
                            final wordsCount = player.words.length;
                            final wordsPerPlayer =
                                provider.settings.wordsPerPlayer;
                            final isWordsFilled = wordsCount >= wordsPerPlayer;
                            final playerName =
                                _controllers[player.id]?.text.trim() ?? '';
                            final hasName = playerName.isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AppInput(
                                      key: ValueKey('input_${player.id}'),
                                      controller: _controllers[player.id],
                                      placeholder: 'Joueur ${index + 1}',
                                      error: error,
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
                                    onTap: hasName
                                        ? () {
                                            provider.setCurrentEditingPlayer(player.id);
                                            provider.goToScreen(AppConstants.screenWords);
                                          }
                                        : null,
                                    child: Opacity(
                                      opacity: hasName ? 1.0 : 0.4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isWordsFilled
                                              ? AppColors.success
                                                  .withValues(alpha: 0.2)
                                              : AppColors.error
                                                  .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isWordsFilled
                                                ? AppColors.success
                                                : AppColors.error,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          isWordsFilled ? 'Remplis' : 'Remplir',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isWordsFilled
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppButton(
                    text: 'Suivant',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    disabled: !canProceed,
                    onPressed:
                        canProceed ? () => _saveAndContinue(provider) : null,
                  ),
                ),
              ],
            ),
          ),
          AppBackButton(
            onPressed: () {
              // Sauvegarder les noms actuels avant de partir
              for (final player in provider.players) {
                final name = _controllers[player.id]?.text.trim() ?? '';
                if (name != player.name) {
                  provider.updatePlayer(player.id, name: name);
                }
              }
              provider.goToScreen(AppConstants.screenSettings);
            },
          ),
        ],
      ),
    );
  }
}
